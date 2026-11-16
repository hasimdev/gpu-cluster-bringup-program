# STAR Stories

One per major risk in the RAID log. Interviewers often pick a risk from a candidate's portfolio and ask what happened, so each of these should be ready to tell in about two minutes.

Fill these in only with what actually happened. If a risk never turned into an issue, the story is about the mitigation that kept it from happening, and that's a fine story to tell. Interviewers can tell when a story has been made up, and NVIDIA interviewers will ask follow-up questions about the technical details.

Format:
- **Situation:** the context, in a sentence or two
- **Task:** what you were responsible for
- **Action:** what you did, in order. Use "I", not "we".
- **Result:** measured outcome, plus what you'd do differently

---

## R1: GPU quota denied or delayed

Likely follow-up questions: How did you know it was on the critical path? What was your fallback? Who did you tell, and when?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**

---

## R2: Driver / CUDA / PyTorch version mismatch

Likely follow-up questions: How did you choose the versions? Who owned the version matrix? How did you stop someone upgrading mid-program?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**

---

## R3: Cost overrun

Likely follow-up questions: How close did you get to the budget? What did the alarm catch? How would this change at 1,000 GPUs?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**

---

## R4: NCCL networking problems in multi-node DDP

Likely follow-up questions: How did you debug a hang with no error message? What did `NCCL_DEBUG=INFO` show? How would InfiniBand change this?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**

---

## R5: Poor scaling without a high-speed interconnect

Likely follow-up questions: What was the scaling efficiency? How did you explain the number to a non-technical stakeholder? What hardware would you recommend instead, and at what cost?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**

---

## Decision story: Kueue vs Slurm (ADR-001)

Likely follow-up questions: Who disagreed? What would make you reverse the decision? How did the onboarding test inform it?

- **Situation:**
- **Task:**
- **Action:**
- **Result:**
