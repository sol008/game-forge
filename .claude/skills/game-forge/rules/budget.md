# Budget rules

Shorelight hit the monthly spend limit twice. Work then had to run one task at a time, and 11 cloud sessions that had not pushed lost about 20 min of work each. There was no forecast, and no spend in the reports.

1. **G0b estimate.** Before phase 0 ends, fill in the worksheet in `forge-tools/cost_estimate.md`: cost per phase, number of cloud sessions, and a range. Shorelight's data points:
   - a cloud session costs about $5–40;
   - the 3D characters team cost about $35;
   - a QA walkthrough session takes 47–108 min.
2. **Ask once**: "Set a spending cap? (No cap / $X / $Y / custom)". The default is **no cap**. Record the answer in REQUIREMENTS.md.
3. **Every status table shows spend so far** next to the estimate. Write it to `docs/forge/spend.txt`.
4. **With a cap**:
   - **at 70%**, warn in the table;
   - **at 90%**, checkpoint: every agent commits and pushes, and work drops to serial;
   - never hit the limit mid-write.
5. **Quota or limit hit anyway**:
   - make every agent and cloud session push first;
   - write a resume note to `docs/forge/followups.md`;
   - tell the user once what is needed (e.g. "raise the monthly limit in settings"). The assistant cannot change billing.
6. **Cheaper equivalents first.**
   - CPU-light work (text, translation, docs) goes to local agents.
   - Cloud sessions are only for CPU-heavy or long, isolated work.
   - Stop each cloud session as soon as its branch is merged.
