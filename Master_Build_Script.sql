
-- ============================================================================
-- Database Script: ExamManagementDB (Master Script)
-- Author: Nesma Osama
-- Description: Full Database Schema, Relations, Seed Data, Stored Procedures,
--              Views, Audit Triggers, Performance Indexes, and Test Workflows.
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE CREATION
-- ============================================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'ExamManagementDB')
BEGIN
    ALTER DATABASE ExamManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamManagementDB;
END
GO

CREATE DATABASE ExamManagementDB;
GO

USE ExamManagementDB;
GO

-- ============================================================================
-- SECTION 2: TABLES CREATION & CONSTRAINTS
-- ============================================================================

CREATE TABLE Department (
    Dept_Id INT IDENTITY(1,1) PRIMARY KEY,
    Dept_Name NVARCHAR(100) NOT NULL
);

CREATE TABLE Student (
    Stud_Id INT IDENTITY(1,1) PRIMARY KEY,
    stud_Fname NVARCHAR(50) NOT NULL,
    Stud_Lname NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Stud_password NVARCHAR(255) NOT NULL,
    Dept_Id INT NULL,
    CONSTRAINT FK_Student_Department FOREIGN KEY (Dept_Id) REFERENCES Department(Dept_Id) ON DELETE SET NULL
);

CREATE TABLE Instructor (
    Inst_Id INT IDENTITY(1,1) PRIMARY KEY,
    Inst_Fname NVARCHAR(50) NOT NULL,
    Inst_Lname NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Dept_ID INT NULL,
    CONSTRAINT FK_Instructor_Department FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_Id) ON DELETE SET NULL
);

CREATE TABLE Course (
    course_id INT IDENTITY(1,1) PRIMARY KEY,
    course_name NVARCHAR(100) NOT NULL,
    course_Description NVARCHAR(MAX) NULL,
    Dept_Id INT NULL,
    Inst_Id INT NULL,
    CONSTRAINT FK_Course_Department FOREIGN KEY (Dept_Id) REFERENCES Department(Dept_Id),
    CONSTRAINT FK_Course_Instructor FOREIGN KEY (Inst_Id) REFERENCES Instructor(Inst_Id) ON DELETE SET NULL
);

CREATE TABLE StudentCourse (
    Stud_Id INT NOT NULL,
    Course_Id INT NOT NULL,
    Enrolment_Date DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (Stud_Id, Course_Id),
    CONSTRAINT FK_StudentCourse_Student FOREIGN KEY (Stud_Id) REFERENCES Student(Stud_Id) ON DELETE CASCADE,
    CONSTRAINT FK_StudentCourse_Course FOREIGN KEY (Course_Id) REFERENCES Course(course_id) ON DELETE CASCADE
);

CREATE TABLE Topic (
    Topic_Id INT IDENTITY(1,1) PRIMARY KEY,
    Topic_Name NVARCHAR(100) NOT NULL,
    Course_Id INT NOT NULL,
    CONSTRAINT FK_Topic_Course FOREIGN KEY (Course_Id) REFERENCES Course(course_id) ON DELETE CASCADE
);

CREATE TABLE Exam (
    Exam_ID INT IDENTITY(1,1) PRIMARY KEY,
    Exam_Name NVARCHAR(100) NOT NULL,
    Duration INT NOT NULL,
    Mark DECIMAL(5,2) NOT NULL,
    NumberOfQuestions INT NOT NULL,
    Course_Id INT NOT NULL,
    Inst_Id INT NULL,
    CONSTRAINT FK_Exam_Course FOREIGN KEY (Course_Id) REFERENCES Course(course_id) ON DELETE CASCADE,
    CONSTRAINT FK_Exam_Instructor FOREIGN KEY (Inst_Id) REFERENCES Instructor(Inst_Id)
);

CREATE TABLE Questions (
    Question_Id INT IDENTITY(1,1) PRIMARY KEY,
    Question_Text NVARCHAR(MAX) NOT NULL,
    Exam_Id INT NOT NULL,
    CONSTRAINT FK_Questions_Exam FOREIGN KEY (Exam_Id) REFERENCES Exam(Exam_ID) ON DELETE CASCADE
);

CREATE TABLE Choices (
    choice_id INT IDENTITY(1,1) PRIMARY KEY,
    Choice_Text NVARCHAR(MAX) NOT NULL,
    IsCorrect BIT NOT NULL DEFAULT 0,
    Question_ID INT NOT NULL,
    CONSTRAINT FK_Choices_Questions FOREIGN KEY (Question_ID) REFERENCES Questions(Question_Id) ON DELETE CASCADE
);

CREATE TABLE StudentExam (
    StudentExamId INT IDENTITY(1,1) PRIMARY KEY,
    Stud_id INT NOT NULL,
    Exam_Id INT NOT NULL,
    Start_Time DATETIME DEFAULT GETDATE(),
    submittime DATETIME NULL,
    Score DECIMAL(5,2) DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT FK_StudentExam_Student FOREIGN KEY (Stud_id) REFERENCES Student(Stud_Id),
    CONSTRAINT FK_StudentExam_Exam FOREIGN KEY (Exam_Id) REFERENCES Exam(Exam_ID)
);

CREATE TABLE StudentAnswer (
    StudentAnswerId INT IDENTITY(1,1) PRIMARY KEY,
    StudentExamId INT NOT NULL,
    Question_ID INT NOT NULL,
    SelectedChoiceId INT NULL,
    CONSTRAINT FK_StudentAnswer_StudentExam FOREIGN KEY (StudentExamId) REFERENCES StudentExam(StudentExamId) ON DELETE CASCADE,
    CONSTRAINT FK_StudentAnswer_Questions FOREIGN KEY (Question_ID) REFERENCES Questions(Question_Id),
    CONSTRAINT FK_StudentAnswer_Choices FOREIGN KEY (SelectedChoiceId) REFERENCES Choices(choice_id)
);
GO

-- ============================================================================
-- SECTION 3: STORED PROCEDURES
-- ============================================================================

CREATE PROC sp_AddStudent
    @stud_fname VARCHAR(50),
    @stud_Lname VARCHAR(50),
    @Email VARCHAR(50),
    @Password VARCHAR(50),
    @dept_id INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT Email FROM Student WHERE Email = @Email)
    BEGIN
        RAISERROR('Email already exists!', 16, 1);
    END
    ELSE
    BEGIN
        INSERT INTO Student (stud_Fname, Stud_Lname, Email, stud_password, Dept_Id)
        VALUES (@stud_fname, @stud_Lname, @Email, @Password, @dept_id);
        
        SELECT SCOPE_IDENTITY() AS NewStudentID;
    END
END;
GO

CREATE PROC sp_AddQuestionWithChoices
    @Question_Text VARCHAR(MAX), 
    @Exam_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Questions (Question_Text, Exam_Id)
    VALUES (@Question_Text, @Exam_Id);

    SELECT SCOPE_IDENTITY() AS NewQuestionID;
END;
GO

CREATE PROC sp_GetExamQuestions 
    @exam_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        q.Question_Id,
        q.Question_Text,
        c.choice_id,
        c.Choice_Text,
        c.IsCorrect
    FROM Questions q
    INNER JOIN Choices c ON q.Question_Id = c.Question_ID
    WHERE q.Exam_Id = @exam_id;
END;
GO

CREATE PROC sp_StartExam
    @stud_id INT,
    @exam_id INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO StudentExam (Stud_id, Exam_Id, Start_Time, Status)
    VALUES (@stud_id, @exam_id, GETDATE(), 'Pending');

    SELECT SCOPE_IDENTITY() AS StudentExamId;
END;
GO

CREATE PROC sp_SaveStudentAnswer
    @studentExamId INT,
    @questionid INT,
    @choiceid INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 
        FROM StudentAnswer 
        WHERE StudentExamId = @studentExamId AND Question_ID = @questionid
    )
    BEGIN
        UPDATE StudentAnswer
        SET SelectedChoiceId = @choiceid
        WHERE StudentExamId = @studentExamId AND Question_ID = @questionid;
    END
    ELSE
    BEGIN
        INSERT INTO StudentAnswer (StudentExamId, Question_ID, SelectedChoiceId)
        VALUES (@studentExamId, @questionid, @choiceid);
    END
END;
GO

CREATE PROC sp_CorrectAndGradeExam
    @studentExamId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FinalScore DECIMAL(5,2), 
            @CorrectCount INT, 
            @QuestionMark DECIMAL(5,2);

    SELECT @QuestionMark = (CAST(e.Mark AS DECIMAL(5,2)) / e.NumberOfQuestions)
    FROM Exam e
    JOIN StudentExam se ON e.Exam_ID = se.Exam_Id
    WHERE se.StudentExamId = @studentExamId;

    SELECT @CorrectCount = COUNT(*)
    FROM StudentAnswer sa
    JOIN Choices c ON sa.SelectedChoiceId = c.choice_id
    WHERE sa.StudentExamId = @studentExamId 
      AND c.IsCorrect = 1;

    SET @FinalScore = @CorrectCount * @QuestionMark;

    UPDATE StudentExam
    SET Score = @FinalScore,
        Status = 'Completed',
        submittime = GETDATE()
    WHERE StudentExamId = @studentExamId;

    SELECT @FinalScore AS FinalScore;
END;
GO

CREATE PROC sp_SubmitExamSafe
    @studentExamId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @FinalScore DECIMAL(5,2), 
                @CorrectCount INT, 
                @QuestionMark DECIMAL(5,2);

        SELECT @QuestionMark = (CAST(e.Mark AS DECIMAL(5,2)) / e.NumberOfQuestions)
        FROM Exam e
        JOIN StudentExam se ON e.Exam_ID = se.Exam_Id
        WHERE se.StudentExamId = @studentExamId;

        SELECT @CorrectCount = COUNT(*)
        FROM StudentAnswer sa
        JOIN Choices c ON sa.SelectedChoiceId = c.choice_id
        WHERE sa.StudentExamId = @studentExamId 
          AND c.IsCorrect = 1;

        SET @FinalScore = @CorrectCount * @QuestionMark;

        UPDATE StudentExam
        SET Score = @FinalScore,
            Status = 'Completed',
            submittime = GETDATE()
        WHERE StudentExamId = @studentExamId;

        COMMIT TRANSACTION;

        SELECT @FinalScore AS FinalScore;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 4: VIEWS
-- ============================================================================

CREATE VIEW v_StudentExamResults
AS
SELECT 
    s.Stud_Id,
    CONCAT(s.stud_Fname, ' ', s.Stud_Lname) AS StudentName,
    c.course_name AS CourseName,
    e.Exam_Name AS ExamName,
    se.Score,
    e.Mark AS TotalMark,
    se.Status,
    se.submittime AS Submition_Time
FROM student s 
INNER JOIN StudentExam se ON s.Stud_Id = se.Stud_id 
INNER JOIN exam e ON se.Exam_Id = e.Exam_ID 
INNER JOIN Course c ON e.Course_Id = c.course_id;
GO

CREATE VIEW v_CourseExamStatistics
AS
SELECT 
    c.course_id,
    c.course_name AS CourseName,
    COUNT(DISTINCT e.Exam_ID) AS Total_Exams,
    COUNT(se.stud_id) AS Total_Student_Attempts,
    MAX(se.score) AS [Highest Score],
    AVG(se.score) AS [Average Score]
FROM course c
LEFT JOIN exam e ON c.course_id = e.Course_Id 
LEFT JOIN StudentExam se ON se.Exam_Id = e.Exam_ID  
GROUP BY c.course_id, c.course_name;
GO

-- ============================================================================
-- SECTION 5: TRIGGERS & INDEXES
-- ============================================================================

CREATE TRIGGER trg_AuditScoreChange
ON studentExam
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(score)
    BEGIN
        IF EXISTS (
            SELECT status FROM deleted WHERE status = 'Completed'
        )
        BEGIN
            RAISERROR('Cannot modify scores for completed exams!', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO

CREATE NONCLUSTERED INDEX IX_StudentAnswer_Exam
ON StudentAnswer(StudentExamId)
INCLUDE (Question_ID, SelectedChoiceId);
GO

-- ============================================================================
-- SECTION 6: INITIAL SEED DATA (SCHEMA & SETUP ONLY)
-- ============================================================================

-- 1. Insert Departments
INSERT INTO Department (Dept_Name) VALUES 
('Computer Science'),
('Information Systems');

-- 2. Insert Students
INSERT INTO Student (stud_Fname, Stud_Lname, Email, stud_password, Dept_Id) VALUES 
('Ahmed', 'Ali', 'ahmed@example.com', '123456', 1),
('Sara', 'Mahmoud', 'sara@example.com', '123456', 2),
('Mona', 'Hassan', 'mona@example.com', '111', 1),
('Youssef', 'Tarek', 'youssef@example.com', '123', 1),
('Nour', 'Adel', 'nour@example.com', '456', 1),
('Hoda', 'Samir', 'hoda@example.com', '789', 1);

-- 3. Insert Instructors
INSERT INTO Instructor (Inst_Fname, Inst_Lname, Email, Dept_ID) VALUES 
('Dr. Mohamed', 'Hassan', 'dr.mohamed@example.com', 1),
('Dr. Eman', 'Khaled', 'dr.eman@example.com', 2);

-- 4. Insert Courses
INSERT INTO Course (course_name, course_Description, Dept_Id, Inst_Id) VALUES 
('Database Systems', 'Introduction to SQL Server and Relational Databases', 1, 1),
('Programming C#', 'Object-Oriented Programming using C#', 1, 2),
('Algorithm Analysis', 'Design and Analysis of Algorithms', 1, 1);

-- 5. Insert Student-Course Enrollments
INSERT INTO StudentCourse (Stud_Id, Course_Id, Enrolment_Date) VALUES 
(1, 1, GETDATE()),
(2, 1, GETDATE()),
(3, 1, GETDATE()),
(1, 2, GETDATE()),
(4, 3, GETDATE()),
(5, 3, GETDATE()),
(6, 3, GETDATE());

-- 6. Insert Topics
INSERT INTO Topic (Topic_Name, Course_Id) VALUES 
('SQL Fundamentals', 1),
('Stored Procedures & Views', 1),
('Asymptotic Complexity & Recurrences', 3);

-- 7. Insert Exams
INSERT INTO Exam (Exam_Name, Duration, Mark, NumberOfQuestions, Course_Id, Inst_Id) VALUES 
('Database Midterm Exam', 60, 100.00, 2, 1, 1),
('Database Final Exam', 60, 100.00, 20, 1, 1),
('Algorithm Midterm Exam', 60, 50.00, 10, 3, 1),
('Algorithm Final Exam', 90, 100.00, 25, 3, 1);

-- 8. Insert Questions for Exam 1 (Database Midterm Exam)
INSERT INTO Questions (Question_Text, Exam_Id) VALUES 
('What does DDL stand for in SQL?', 1),
('Which statement is used to fetch data from a table?', 1);

-- 9. Insert Question Choices for Exam 1
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Data Definition Language', 1, 1),
('Data Description Language', 0, 1),
('Data Design Language', 0, 1),
('Data Distribution Language', 0, 1),
('INSERT', 0, 2),
('SELECT', 1, 2),
('UPDATE', 0, 2),
('DELETE', 0, 2);

-- 10. Insert Questions for Exam 2 (Database Final Exam)
INSERT INTO Questions (Question_Text, Exam_Id) VALUES 
('Which SQL keyword is used to sort the result-set?', 2),
('What is the default sort order for ORDER BY clause?', 2);

-- 11. Insert Question Choices for Exam 2
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('ORDER BY', 1, 3),
('SORT BY', 0, 3),
('GROUP BY', 0, 3),
('ARRANGE BY', 0, 3),
('Ascending (ASC)', 1, 4),
('Descending (DESC)', 0, 4);
GO

-- ============================================================================
-- SECTION 7: AUTOMATED DYNAMIC TEST WORKFLOW
-- ============================================================================

-- Dynamic Test Setup
INSERT INTO Department (Dept_Name) VALUES ('Computer Science');
DECLARE @DeptId INT = SCOPE_IDENTITY();

INSERT INTO Course (course_name, Dept_Id) VALUES ('Database Systems', @DeptId);
DECLARE @CourseId INT = SCOPE_IDENTITY();

INSERT INTO Exam (Exam_Name, Mark, NumberOfQuestions, Duration, Course_Id) VALUES ('Database Midterm', 100, 2, 60, @CourseId);
DECLARE @ExamId INT = SCOPE_IDENTITY();

INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What does SQL stand for?', @ExamId);
DECLARE @Q1_Id INT = SCOPE_IDENTITY();

INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Structured Query Language', 1, @Q1_Id),
('Simple Question Language', 0, @Q1_Id);

INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which clause is used to filter records?', @ExamId);
DECLARE @Q2_Id INT = SCOPE_IDENTITY();

INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('WHERE', 1, @Q2_Id),
('GROUP BY', 0, @Q2_Id);

EXEC sp_AddStudent 'Nesma', 'Osama', 'nesma_test2@test.com', 'pass123', @DeptId;

SELECT 
    @ExamId AS GeneratedExamID, 
    @Q1_Id AS Question1_ID, 
    @Q2_Id AS Question2_ID;
GO

-- Automated Exam Execution
DECLARE @StudId INT = 6;
DECLARE @ExamId INT;
DECLARE @Q1_Id INT, @Q2_Id INT;
DECLARE @CorrectChoice_Q1 INT, @WrongChoice_Q2 INT;
DECLARE @StudentExamId INT;

SELECT TOP 1 @ExamId = Exam_ID FROM Exam ORDER BY Exam_ID DESC;
SELECT @Q1_Id = MIN(Question_Id), @Q2_Id = MAX(Question_Id) FROM Questions WHERE Exam_Id = @ExamId;
SELECT TOP 1 @CorrectChoice_Q1 = choice_id FROM Choices WHERE Question_ID = @Q1_Id AND IsCorrect = 1;
SELECT TOP 1 @WrongChoice_Q2 = choice_id FROM Choices WHERE Question_ID = @Q2_Id AND IsCorrect = 0;

EXEC sp_StartExam @stud_id = @StudId, @exam_id = @ExamId;

SELECT TOP 1 @StudentExamId = StudentExamId FROM StudentExam WHERE Stud_id = @StudId ORDER BY StudentExamId DESC;

EXEC sp_SaveStudentAnswer @StudentExamId, @Q1_Id, @CorrectChoice_Q1;
EXEC sp_SaveStudentAnswer @StudentExamId, @Q2_Id, @WrongChoice_Q2;

EXEC sp_SubmitExamSafe @studentExamId = @StudentExamId;
GO
