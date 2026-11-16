"""Minimal PyTorch DDP throughput benchmark.

Trains a small convolutional network on random data so the result depends on
the GPUs and the network between them, not on a dataset or disk. Rank 0 prints
throughput in samples per second, summed over all ranks.

Launch with torchrun, one process per GPU:

    # single node, single GPU (baseline)
    torchrun --nproc-per-node=1 train_ddp.py

    # two nodes, one GPU each
    torchrun --nnodes=2 --nproc-per-node=1 --node-rank=<0|1> \
        --master-addr=<node0> --master-port=29500 train_ddp.py

Scaling efficiency = (2-GPU throughput) / (2 x 1-GPU throughput).

Use --cpu to smoke-test the script on a machine without a GPU (gloo backend).
"""

import argparse
import os
import time

import torch
import torch.distributed as dist
import torch.nn as nn
from torch.nn.parallel import DistributedDataParallel as DDP


def build_model(width: int) -> nn.Module:
    """A ResNet-ish stack, big enough that gradient all-reduce is not trivial."""
    layers = [nn.Conv2d(3, width, 3, padding=1), nn.BatchNorm2d(width), nn.ReLU()]
    for _ in range(6):
        layers += [
            nn.Conv2d(width, width, 3, padding=1),
            nn.BatchNorm2d(width),
            nn.ReLU(),
        ]
    layers += [nn.AdaptiveAvgPool2d(1), nn.Flatten(), nn.Linear(width, 1000)]
    return nn.Sequential(*layers)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--batch-size", type=int, default=64, help="per-GPU batch size")
    p.add_argument("--image-size", type=int, default=128)
    p.add_argument("--width", type=int, default=256, help="conv channels")
    p.add_argument("--warmup-steps", type=int, default=20)
    p.add_argument("--steps", type=int, default=200, help="timed steps")
    p.add_argument("--duration-minutes", type=float, default=0.0,
                   help="if set, run timed steps for this long instead (burn-in)")
    p.add_argument("--amp", action="store_true", help="use bfloat16 autocast")
    p.add_argument("--cpu", action="store_true", help="smoke test without a GPU")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    use_cuda = torch.cuda.is_available() and not args.cpu
    backend = "nccl" if use_cuda else "gloo"
    dist.init_process_group(backend=backend)

    rank = dist.get_rank()
    world_size = dist.get_world_size()
    local_rank = int(os.environ.get("LOCAL_RANK", 0))

    if use_cuda:
        torch.cuda.set_device(local_rank)
        device = torch.device("cuda", local_rank)
        torch.backends.cudnn.benchmark = True
    else:
        device = torch.device("cpu")

    model = build_model(args.width).to(device)
    ddp_model = DDP(model, device_ids=[local_rank] if use_cuda else None)
    optimizer = torch.optim.SGD(ddp_model.parameters(), lr=0.01, momentum=0.9)
    loss_fn = nn.CrossEntropyLoss()

    # Fixed random batch kept on the device: no data loading in the timed loop.
    x = torch.randn(args.batch_size, 3, args.image_size, args.image_size, device=device)
    y = torch.randint(0, 1000, (args.batch_size,), device=device)

    def step() -> None:
        optimizer.zero_grad(set_to_none=True)
        with torch.autocast(device_type=device.type, dtype=torch.bfloat16, enabled=args.amp):
            loss = loss_fn(ddp_model(x), y)
        loss.backward()
        optimizer.step()

    def sync() -> None:
        if use_cuda:
            torch.cuda.synchronize()

    if rank == 0:
        gpu = torch.cuda.get_device_name(device) if use_cuda else "cpu"
        print(f"world_size={world_size} backend={backend} device={gpu} "
              f"batch_per_rank={args.batch_size} image={args.image_size} amp={args.amp}",
              flush=True)

    for _ in range(args.warmup_steps):
        step()
    sync()
    dist.barrier()

    steps_done = 0
    start = time.perf_counter()
    deadline = start + args.duration_minutes * 60 if args.duration_minutes > 0 else None
    report_every = 50

    while True:
        step()
        steps_done += 1

        if deadline is None:
            if steps_done >= args.steps:
                break
        elif steps_done % report_every == 0:
            # Every rank must agree on when to stop, or the last all-reduce hangs.
            done = torch.tensor(
                [1.0 if time.perf_counter() >= deadline else 0.0], device=device
            )
            dist.all_reduce(done, op=dist.ReduceOp.MAX)
            sync()
            if rank == 0:
                elapsed = time.perf_counter() - start
                rate = steps_done * args.batch_size * world_size / elapsed
                print(f"[{elapsed / 60:6.1f} min] {rate:,.1f} samples/s", flush=True)
            if done.item() > 0:
                break

    sync()
    elapsed = time.perf_counter() - start

    # Report the slowest rank's time, since that is what the job actually took.
    t = torch.tensor([elapsed], device=device)
    dist.all_reduce(t, op=dist.ReduceOp.MAX)
    elapsed = t.item()

    if rank == 0:
        total_samples = steps_done * args.batch_size * world_size
        throughput = total_samples / elapsed
        print(f"RESULT world_size={world_size} steps={steps_done} "
              f"elapsed_s={elapsed:.2f} samples_per_s={throughput:,.1f} "
              f"samples_per_s_per_gpu={throughput / world_size:,.1f}",
              flush=True)

    dist.destroy_process_group()


if __name__ == "__main__":
    main()
