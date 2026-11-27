# Kaizora AI Academy Course Upload Area

Upload each complete course as **one JSON file** directly into this folder.

**Do not upload course files into subfolders.** The importer expects one course JSON per file in this directory. Keep the category and level inside the JSON metadata so courses are grouped correctly in the LMS.

## Upload naming convention

Use:
`S3_Developer_Environment_Setup.json`
`C01_Introduction_to_Artificial_Intelligence.json`
`C02_Prompt_Engineering_and_AI_Interaction.json`

Use the course ID/order below as the filename prefix. Keep the existing S1 and S2 filenames.

## Catalogue structure

### Setup courses (4)
- S1 — Computer and Internet Readiness — Beginner
- S2 — AI Toolkit Setup — Beginner
- S3 — Developer Environment Setup — Beginner
- S4 — Automation Lab Setup — Beginner

### Category 1: AI Foundations (4)
- 01 — Introduction to Artificial Intelligence — Beginner
- 02 — Prompt Engineering and AI Interaction — Intermediate
- 03 — AI Research and Productivity — Intermediate
- 04 — Responsible AI and AI Safety — Beginner

### Category 2: AI Content and Creativity (3)
- 05 — AI Marketing and Creative Production — Intermediate
- 06 — AI Branding and Design — Intermediate
- 07 — AI-Powered Content Creation and Video Production — Intermediate

### Category 3: Automation and Business Applications (8)
- 08 — Workflow and Business Process Automation — Intermediate
- 09 — APIs and Webhooks for Automation — Intermediate
- 10 — AI Automation for Business — Intermediate
- 11 — AI for Business Management — Intermediate
- 12 — Building AI Agents — Advanced
- 13 — RAG and Vector Databases — Advanced
- 14 — Chatbots and Customer Support Bots — Intermediate
- 15 — AI for Spreadsheets and Finance — Intermediate

### Category 4: Software and Development (4)
- 16 — Web Development Fundamentals — Intermediate
- 17 — AI-Assisted Application Development — Intermediate
- 18 — Database Fundamentals — Intermediate
- 19 — Vibe Coding — Intermediate

### Category 5: Data and Programming (3)
- 20 — Data Literacy — Beginner
- 21 — Python Programming — Intermediate
- 22 — Data Analysis with AI — Intermediate

### Category 6: Cybersecurity and Secure Development (3)
- 23 — Cybersecurity Fundamentals — Beginner
- 24 — Introduction to DevSecOps — Intermediate
- 25 — AI Security — Advanced

### Category 7: Emerging Technology (2)
- 26 — Robotics and Intelligent Systems — Intermediate
- 27 — Voice AI — Intermediate

### Category 8: Career and Specialised Tracks (2)
- 28 — Freelancing and Careers with AI — Intermediate
- 29 — AI for Teachers and Trainers — Intermediate

### Category 9: Advanced AI Engineering (3)
- 30 — Machine Learning with Python — Advanced
- 31 — Deep Learning and Neural Networks — Advanced
- 32 — LLM Engineering — Advanced

## Required course metadata

Every JSON file must include:
- `course_id`: unique ID matching the catalogue (S1–S4 or C01–C32; keep the catalogue number in the ID even though the display order is listed above).
- `title`
- `category`: exact category name from this README
- `level`: Beginner, Intermediate, or Advanced
- `description`
- `modules`: ordered modules, each with ordered lessons

Preserve the full lesson content, exercises, assessments, and answer keys in the course JSON format already used by S1 and S2. Do not put secrets, API keys, passwords, or real learner information in course files.

## Catalogue totals
- 4 setup courses + 32 main courses = **36 courses**
- Beginner: **8**
- Intermediate: **22**
- Advanced: **6**

## Import safety
Uploading a JSON file here does **not** publish it to the LMS by itself. Course files must be schema-validated and imported into the development database first. Production publishing is a separate approval step.
