import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const directory = path.join(process.cwd(), "content", "courses");
const files = (await readdir(directory)).filter((file) => file.endsWith(".json")).sort();
const errors = [];
let moduleCount = 0;
let lessonCount = 0;
let assessmentCount = 0;
const courseIds = new Set();

function requireString(value, label, file) {
  if (typeof value !== "string" || value.trim().length === 0) {
    errors.push(`${file}: ${label} must be a non-empty string`);
  }
}

function validateQuestions(questions, label, file) {
  if (!Array.isArray(questions) || questions.length === 0) {
    errors.push(`${file}: ${label} must contain at least one question`);
    return;
  }
  questions.forEach((question, index) => {
    const prefix = `${label} question ${index + 1}`;
    requireString(question.question, `${prefix}.question`, file);
    if (!Array.isArray(question.options) || question.options.length < 2) {
      errors.push(`${file}: ${prefix}.options must contain at least two choices`);
    } else if (!question.options.includes(question.correct_answer)) {
      errors.push(`${file}: ${prefix}.correct_answer must match one of its options`);
    }
    requireString(question.explanation, `${prefix}.explanation`, file);
    assessmentCount += 1;
  });
}

for (const file of files) {
  let course;
  try {
    course = JSON.parse(await readFile(path.join(directory, file), "utf8"));
  } catch (error) {
    errors.push(`${file}: invalid JSON (${error.message})`);
    continue;
  }

  requireString(course.course_id, "course_id", file);
  requireString(course.title, "title", file);
  requireString(course.category, "category", file);
  requireString(course.level, "level", file);
  requireString(course.description, "description", file);

  if (courseIds.has(course.course_id)) errors.push(`${file}: duplicate course_id ${course.course_id}`);
  courseIds.add(course.course_id);

  if (!Array.isArray(course.what_you_will_need) || course.what_you_will_need.length === 0) {
    errors.push(`${file}: what_you_will_need must be a non-empty array`);
  }
  if (!Array.isArray(course.learning_objectives) || course.learning_objectives.length === 0) {
    errors.push(`${file}: learning_objectives must be a non-empty array`);
  }
  if (!Array.isArray(course.modules) || course.modules.length === 0) {
    errors.push(`${file}: modules must be a non-empty array`);
    continue;
  }

  const moduleNumbers = new Set();
  for (const courseModule of course.modules) {
    moduleCount += 1;
    if (!Number.isInteger(courseModule.module_number) || courseModule.module_number < 1) {
      errors.push(`${file}: module_number must be a positive integer`);
    }
    if (moduleNumbers.has(courseModule.module_number)) errors.push(`${file}: duplicate module_number ${courseModule.module_number}`);
    moduleNumbers.add(courseModule.module_number);
    requireString(courseModule.module_title, `module ${courseModule.module_number} title`, file);
    requireString(courseModule.module_goal, `module ${courseModule.module_number} goal`, file);

    if (!Array.isArray(courseModule.lessons) || courseModule.lessons.length === 0) {
      errors.push(`${file}: module ${courseModule.module_number} must contain lessons`);
      continue;
    }

    const lessonNumbers = new Set();
    for (const lesson of courseModule.lessons) {
      lessonCount += 1;
      requireString(lesson.lesson_number, "lesson_number", file);
      requireString(lesson.lesson_title, "lesson_title", file);
      requireString(lesson.simple_explanation, `${lesson.lesson_number} simple_explanation`, file);
      if (lessonNumbers.has(lesson.lesson_number)) errors.push(`${file}: duplicate lesson_number ${lesson.lesson_number}`);
      lessonNumbers.add(lesson.lesson_number);

      if (!Array.isArray(lesson.step_by_step_guide) || lesson.step_by_step_guide.length === 0) {
        errors.push(`${file}: lesson ${lesson.lesson_number} needs step_by_step_guide`);
      }
      if (!Array.isArray(lesson.key_terms) || lesson.key_terms.length === 0) {
        errors.push(`${file}: lesson ${lesson.lesson_number} needs key_terms`);
      }
      if (!lesson.practical_exercise || typeof lesson.practical_exercise !== "object") {
        errors.push(`${file}: lesson ${lesson.lesson_number} needs practical_exercise`);
      }
      validateQuestions(lesson.lesson_quiz, `lesson ${lesson.lesson_number} quiz`, file);
    }

    if (courseModule.module_quiz?.questions) {
      validateQuestions(courseModule.module_quiz.questions, `module ${courseModule.module_number} quiz`, file);
    }
  }

  if (course.final_assessment?.questions) {
    validateQuestions(course.final_assessment.questions, "final assessment", file);
  } else {
    errors.push(`${file}: final_assessment.questions is required`);
  }
}

console.log(`Course files: ${files.length}; modules: ${moduleCount}; lessons: ${lessonCount}; assessment questions: ${assessmentCount}`);
if (errors.length) {
  console.error(errors.map((error) => `- ${error}`).join("\n"));
  process.exitCode = 1;
} else {
  console.log("All course JSON files passed structural validation.");
}
