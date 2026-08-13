-- ============================================================================
-- Database Script: ExamManagementDB (Master Setup Script)
-- Author: Nesma Osama
-- Description: Complete SQL Schema, Relational Integrity Constraints, 
--              Stored Procedures, Views, Audit Triggers, Indexes, 
--              and Complete Seed Data with Exact Student IDs.
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE CREATION & CLEANUP
-- ============================================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'ExamManagementDB')
BEGIN
    ALTER DATABASE ExamManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamManagementDB;
END;
GO

CREATE DATABASE ExamManagementDB;
GO

USE ExamManagementDB;
GO

-- ============================================================================
-- SECTION 2: TABLES CREATION & CONSTRAINTS (11 Tables)
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
        INSERT INTO Student (stud_Fname, Stud_Lname, Email, Stud_password, Dept_Id)
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

CREATE PROC sp_SubmitExamSafe
    @studentExamId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ExamID INT;
        DECLARE @TotalQuestions INT = 0;
        DECLARE @CorrectQuestions INT = 0;
        DECLARE @MaxMark DECIMAL(5,2) = 100.00;
        DECLARE @FinalScore DECIMAL(5,2) = 0.00;

        SELECT 
            @ExamID = se.Exam_Id,
            @MaxMark = ISNULL(e.Mark, 100.00)
        FROM StudentExam se
        INNER JOIN Exam e ON se.Exam_Id = e.Exam_ID
        WHERE se.StudentExamId = @studentExamId;

        SELECT @TotalQuestions = COUNT(*) 
        FROM Questions 
        WHERE Exam_Id = @ExamID;

        SELECT @CorrectQuestions = COUNT(DISTINCT sa.Question_ID)
        FROM StudentAnswer sa
        INNER JOIN Choices c ON sa.SelectedChoiceId = c.choice_id
        WHERE sa.StudentExamId = @studentExamId 
          AND c.IsCorrect = 1;

        IF @TotalQuestions > 0
        BEGIN
            SET @FinalScore = (CAST(@CorrectQuestions AS DECIMAL(5,2)) / @TotalQuestions) * @MaxMark;
        END

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
    se.submittime AS Submission_Time
FROM Student s 
INNER JOIN StudentExam se ON s.Stud_Id = se.Stud_id 
INNER JOIN Exam e ON se.Exam_Id = e.Exam_ID 
INNER JOIN Course c ON e.Course_Id = c.course_id;
GO

CREATE VIEW v_CourseExamStatistics
AS
SELECT 
    c.course_id,
    c.course_name AS CourseName,
    COUNT(DISTINCT e.Exam_ID) AS Total_Exams,
    COUNT(se.Stud_id) AS Total_Student_Attempts,
    MAX(se.Score) AS [Highest Score],
    AVG(se.Score) AS [Average Score]
FROM Course c
LEFT JOIN Exam e ON c.course_id = e.Course_Id 
LEFT JOIN StudentExam se ON se.Exam_Id = e.Exam_ID  
GROUP BY c.course_id, c.course_name;
GO

-- ============================================================================
-- SECTION 5: TRIGGERS & INDEXES
-- ============================================================================

CREATE TRIGGER trg_AuditScoreChange
ON StudentExam
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Score)
    BEGIN
        IF EXISTS (
            SELECT Status FROM deleted WHERE Status = 'Completed'
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
-- SECTION 6: INITIAL SEED DATA
-- ============================================================================

-- 1. Insert Departments
INSERT INTO Department (Dept_Name) VALUES 
('Computer Science'),
('Information Systems');

-- 2. Insert Students (Using Exact IDs & Data from Image)
SET IDENTITY_INSERT Student ON;

INSERT INTO Student (Stud_Id, stud_Fname, Stud_Lname, Email, Stud_password, Dept_Id) VALUES 
(1,    'Ahmed',   'Ali',     'ahmed@example.com',       '123456',  NULL),
(2,    'Sara',    'Mahmoud', 'sara@example.com',        '123456',  2),
(6,    'Nesma',   'Osama',   'nesma_test2@test.com',    'pass123', 1),
(1006, 'Mona',    'Hassan',  'mona@email.com',          '111',     NULL),
(1007, 'Youssef', 'Tarek',   'youssef@email.com',       '123',     NULL),
(1008, 'Nour',    'Adel',    'nour@email.com',          '456',     NULL),
(1009, 'Hoda',    'Samir',   'hoda@email.com',          '789',     NULL),
(1011, 'Omar',    'Hassan',  'omar.hassan@example.com', '123456',  NULL);

SET IDENTITY_INSERT Student OFF;

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
(6,    1, GETDATE()), 
(1,    1, GETDATE()), 
(2,    1, GETDATE()), 
(6,    2, GETDATE()), 
(1006, 3, GETDATE()),
(1007, 3, GETDATE()),
(1008, 3, GETDATE()),
(1011, 3, GETDATE()); 

-- 6. Insert Topics
INSERT INTO Topic (Topic_Name, Course_Id) VALUES 
('SQL Fundamentals', 1),
('Stored Procedures & Views', 1),
('Asymptotic Complexity & Recurrences', 3);

-------------------------------------------------------------------------------
-- EXAM 1: Database Midterm Exam (10 Questions / 40 Choices)
-------------------------------------------------------------------------------
INSERT INTO Exam (Exam_Name, Duration, Mark, NumberOfQuestions, Course_Id, Inst_Id) 
VALUES ('Database Midterm Exam', 60, 100.00, 10, 1, 1);

DECLARE @DbExamID INT = SCOPE_IDENTITY();
DECLARE @QID INT;

-- Q1
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What does DDL stand for in SQL?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Data Definition Language', 1, @QID), ('Data Description Language', 0, @QID),
('Data Design Language', 0, @QID), ('Data Distribution Language', 0, @QID);

-- Q2
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which statement is used to fetch data from a table?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('INSERT', 0, @QID), ('SELECT', 1, @QID), ('UPDATE', 0, @QID), ('DELETE', 0, @QID);

-- Q3
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which clause is used to filter group records in SQL?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('HAVING', 1, @QID), ('WHERE', 0, @QID), ('GROUP BY', 0, @QID), ('ORDER BY', 0, @QID);

-- Q4
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which command is used to remove all records from a table without logging individual row deletions?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('TRUNCATE', 1, @QID), ('DELETE', 0, @QID), ('DROP', 0, @QID), ('REMOVE', 0, @QID);

-- Q5
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What does the primary key constraint enforce in a table?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Uniqueness and Non-nullability', 1, @QID), ('Foreign Key relationships only', 0, @QID),
('Auto-incrementing values only', 0, @QID), ('Default values for columns', 0, @QID);

-- Q6
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which SQL join returns all records when there is a match in either left or right table?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('FULL OUTER JOIN', 1, @QID), ('INNER JOIN', 0, @QID), ('LEFT JOIN', 0, @QID), ('RIGHT JOIN', 0, @QID);

-- Q7
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which aggregate function returns the average value of a numeric column?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('AVG()', 1, @QID), ('SUM()', 0, @QID), ('COUNT()', 0, @QID), ('MEAN()', 0, @QID);

-- Q8
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the default sorting order of ORDER BY clause in SQL?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('ASC (Ascending)', 1, @QID), ('DESC (Descending)', 0, @QID), ('Random', 0, @QID), ('Unsorted', 0, @QID);

-- Q9
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which statement is used to modify existing records in a table?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('UPDATE', 1, @QID), ('MODIFY', 0, @QID), ('ALTER', 0, @QID), ('CHANGE', 0, @QID);

-- Q10
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which SQL constraint ensures that all values in a column are unique?', @DbExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('UNIQUE', 1, @QID), ('CHECK', 0, @QID), ('PRIMARY KEY only', 0, @QID), ('DISTINCT', 0, @QID);

-------------------------------------------------------------------------------
-- EXAM 2: Algorithm Analysis Final Exam (8 Questions / 32 Choices)
-------------------------------------------------------------------------------
INSERT INTO Exam (Exam_Name, Duration, Mark, NumberOfQuestions, Course_Id, Inst_Id) 
VALUES ('Algorithm Final Exam', 90, 100.00, 8, 3, 1);

DECLARE @AlgoExamID INT = SCOPE_IDENTITY();

-- Q1
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the average time complexity of Quick Sort?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(N^2)', 0, @QID), ('O(N log N)', 1, @QID), ('O(N)', 0, @QID), ('O(1)', 0, @QID);

-- Q2
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the worst-case time complexity of Binary Search on a sorted array?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(1)', 0, @QID), ('O(N)', 0, @QID), ('O(log N)', 1, @QID), ('O(N log N)', 0, @QID);

-- Q3
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which notation is used to describe the upper bound of an algorithm execution time?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Big-O Notation', 1, @QID), ('Big-Omega Notation', 0, @QID), ('Big-Theta Notation', 0, @QID), ('Little-o Notation', 0, @QID);

-- Q4
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the worst-case time complexity of Merge Sort?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(N^2)', 0, @QID), ('O(N log N)', 1, @QID), ('O(N)', 0, @QID), ('O(log N)', 0, @QID);

-- Q5
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('Which algorithmic strategy solves subproblems only once and stores their solutions in a table?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('Greedy Approach', 0, @QID), ('Divide and Conquer', 0, @QID), ('Dynamic Programming', 1, @QID), ('Backtracking', 0, @QID);

-- Q6
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the auxiliary space complexity of Merge Sort?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(1)', 0, @QID), ('O(log N)', 0, @QID), ('O(N)', 1, @QID), ('O(N log N)', 0, @QID);

-- Q7
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the best-case time complexity of Bubble Sort when optimized with a swapped flag?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(N)', 1, @QID), ('O(N^2)', 0, @QID), ('O(log N)', 0, @QID), ('O(1)', 0, @QID);

-- Q8
INSERT INTO Questions (Question_Text, Exam_Id) VALUES ('What is the time complexity of searching for an element in an unsorted array of size N?', @AlgoExamID);
SET @QID = SCOPE_IDENTITY();
INSERT INTO Choices (Choice_Text, IsCorrect, Question_ID) VALUES 
('O(1)', 0, @QID), ('O(log N)', 0, @QID), ('O(N)', 1, @QID), ('O(N log N)', 0, @QID);
GO
