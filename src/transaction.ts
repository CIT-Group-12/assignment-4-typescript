// Part B1 - one operation, two statements, one transaction

import { pool } from './db.js';

export interface EnrolInput {
  studentId: string;
  courseId: string;
  secId: string;
  semester: string;
  year: number;
}

/**
 * Enrols a student in a course section and adds the course credits to the
 * student's total.
 *
 * Two statements:
 *   INSERT INTO takes (id, course_id, sec_id, semester, year, grade)
 *     VALUES ($1, $2, $3, $4, $5, NULL)
 *   UPDATE student SET tot_cred = tot_cred + <the course credits>
 *     WHERE id = $1
 *
 * They must both happen or neither. A student enrolled without the credits
 * being added is a database that quietly disagrees with itself.
 *
 * A transaction runs on one connection, so take a client from the pool
 * rather than using the pool directly: BEGIN, both statements, COMMIT, and
 * ROLLBACK if anything fails. Release the client in a finally block.
 *
 * Returns the student's new credit total.
 */
export async function enrolInTypeScript(input: EnrolInput): Promise<number> {
  const client = await pool.connect();
  try {
    //start new client
    await client.query('BEGIN');

    // enrolls student in course (takes)
    await client.query(
      `INSERT INTO takes (id, course_id, sec_id, semester, year, grade)
       VALUES ($1, $2, $3, $4, $5, NULL)`,
      [input.studentId, input.courseId, input.secId, input.semester, input.year],
    );

    // get course credits (course.credits)
    const { rows } = await client.query(
      `SELECT credits
       FROM course
       WHERE course_id = $1`,
      [input.courseId],
    );
    
    if (rows.length === 0) {
      throw new Error(`Course ${input.courseId} does not exist`);
    }

    const credits = Number(rows[0].credits);

    // add and return course credits (student.tot_cred)
    const newTotCred = await client.query<{ totCred: string }>(
      `UPDATE student
       SET tot_cred = tot_cred + $2
       WHERE id = $1
       RETURNING tot_cred AS "totCred"`,
      [input.studentId, credits],
    );

    if (newTotCred.rows.length === 0) {
      throw new Error(`Student ${input.studentId} does not exist`);
    }

    await client.query('COMMIT');
    return Number(newTotCred.rows[0].totCred);

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;

  } finally {
    client.release();
    
  }
}
