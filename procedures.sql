-- The routines you write in the database.
--
-- Write them in pgAdmin against the university database, test them there,
-- and then call them from TypeScript. Fill in the parts marked TODO.
--
-- B2. A FUNCTION that queries and returns a result set.
--
-- student_transcript(p_id) returns one row per course the student takes,
-- with the course id, the title, and the grade converted to the Danish
-- 7-point scale. Order by course id.
--
-- Unlike danish_grade, this one reads tables and needs control flow, so it
-- is written in plpgsql. It must raise an exception when the student does
-- not exist:
--
--     RAISE EXCEPTION 'No student with id %', p_id;
--
-- A trap: CREATE OR REPLACE FUNCTION fails once you change which columns it
-- returns. The message tells you to drop it first:
--
--     DROP FUNCTION student_transcript(varchar);

CREATE OR REPLACE FUNCTION student_transcript(p_id varchar)
RETURNS TABLE (course_id varchar, title varchar, grade varchar)
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM student AS s
    WHERE s.id = p_id
  ) THEN
    RAISE EXCEPTION 'No student with id %', p_id;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM takes AS t
    WHERE t.id = p_id
      AND t.grade IS NOT NULL
      AND t.grade NOT IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F')
  ) THEN
    RAISE EXCEPTION 'Unsupported grade in transcript for student %', p_id
      USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT t.course_id, c.title,
    CASE t.grade
      WHEN 'A'  THEN '12'
      WHEN 'A-' THEN '10'
      WHEN 'B+' THEN '10'
      WHEN 'B'  THEN '7'
      WHEN 'B-' THEN '7'
      WHEN 'C+' THEN '7'
      WHEN 'C'  THEN '4'
      WHEN 'C-' THEN '02'
      WHEN 'D+' THEN '02'
      WHEN 'D'  THEN '00'
      WHEN 'D-' THEN '00'
      WHEN 'F'  THEN '-3'
      ELSE NULL
    END::varchar
  FROM takes AS t
  JOIN course AS c ON c.course_id = t.course_id
  WHERE t.id = p_id
  ORDER BY t.course_id;
END;
$$;

-- Test it:
--     SELECT * FROM student_transcript('00128');   -- two rows, grades 12 and 10
--     SELECT * FROM student_transcript('99999');   -- an error


-- B3. A PROCEDURE that changes several things.
--
-- enrol_student must:
--   look up the credits of the course, and raise an exception when the
--     course does not exist
--   insert a row into takes, with a null grade
--   add the course credits to the student's tot_cred
--   report the student's new total through the INOUT parameter
--
-- A procedure, not a function, because it exists to change things rather
-- than to answer a question.

CREATE OR REPLACE PROCEDURE enrol_student(
  p_id varchar,
  p_course_id varchar,
  p_sec_id varchar,
  p_semester varchar,
  p_year numeric,
  INOUT new_total numeric DEFAULT NULL)
LANGUAGE plpgsql AS $$
DECLARE
  v_credits numeric;
BEGIN

  SELECT credits
  INTO v_credits
  FROM course
  WHERE course_id = p_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No such course: %', p_course_id;
  END IF;

  INSERT INTO takes (
    id, course_id, sec_id, semester, year, grade
  )
  VALUES (
    p_id, p_course_id, p_sec_id, p_semester, p_year, NULL
  );

  UPDATE student
  SET tot_cred = tot_cred + v_credits
  WHERE id = p_id
  RETURNING tot_cred INTO new_total;

END;
$$;

-- Test it:
--     CALL enrol_student('70557', 'CS-319', '1', 'Spring', 2018);
