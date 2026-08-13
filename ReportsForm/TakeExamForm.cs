using System;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace ReportsForm
{
    public partial class TakeExamForm : Form
    {
        private string connString = @"Server=localhost;Database=ExamManagementDB;Trusted_Connection=True;TrustServerCertificate=True;";
        private int currentStudentExamId = 0;
        private FlowLayoutPanel examPanel;

        public TakeExamForm()
        {
            InitializeComponent();
            SetupExamContainer();
        }

        private void SetupExamContainer()
        {
            if (dataGridView1 != null) dataGridView1.Visible = false;

            examPanel = new FlowLayoutPanel
            {
                Location = new Point(20, 80),
                Size = new Size(this.ClientSize.Width - 40, this.ClientSize.Height - 100),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                AutoScroll = true,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                BackColor = Color.White,
                Padding = new Padding(15)
            };

            this.Controls.Add(examPanel);
            examPanel.BringToFront();
        }

        private void TakeExamForm_Load_1(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Maximized;
            this.Text = "Take Exam - Student Portal";
            LoadExamsToComboBox();
        }

        private void LoadExamsToComboBox()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();
                    string query = @"
                        SELECT DISTINCT c.Course_ID, c.Course_Name 
                        FROM Course c
                        INNER JOIN Exam e ON c.Course_ID = e.Course_ID";

                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        SqlDataAdapter da = new SqlDataAdapter(cmd);
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        comboBox1.DataSource = dt;
                        comboBox1.DisplayMember = "Course_Name";
                        comboBox1.ValueMember = "Course_ID";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading courses: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (!int.TryParse(textBox1.Text, out int studentId))
            {
                MessageBox.Show("Please enter a valid Student ID.", "Validation Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (comboBox1.SelectedValue == null || !int.TryParse(comboBox1.SelectedValue.ToString(), out int courseId))
            {
                MessageBox.Show("Please select a course.", "Validation Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();

                  
                    int examId = 0;
                    string getExamQuery = "SELECT TOP 1 Exam_ID FROM Exam WHERE Course_ID = @crs_id";
                    using (SqlCommand cmdGetExam = new SqlCommand(getExamQuery, conn))
                    {
                        cmdGetExam.Parameters.AddWithValue("@crs_id", courseId);
                        object res = cmdGetExam.ExecuteScalar();
                        if (res != null && res != DBNull.Value)
                        {
                            examId = Convert.ToInt32(res);
                        }
                    }

                    if (examId == 0)
                    {
                        MessageBox.Show("No active exam found for this selected course.", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        return;
                    }

                  
                    using (SqlCommand cmdStart = new SqlCommand("sp_StartExam", conn))
                    {
                        cmdStart.CommandType = CommandType.StoredProcedure;
                        cmdStart.Parameters.AddWithValue("@stud_id", studentId);
                        cmdStart.Parameters.AddWithValue("@exam_id", examId);

                        object result = cmdStart.ExecuteScalar();
                        if (result != null)
                        {
                            currentStudentExamId = Convert.ToInt32(result);
                        }
                    }

                   
                    DataTable dt = new DataTable();
                    using (SqlCommand cmdQuestions = new SqlCommand("sp_GetExamQuestions", conn))
                    {
                        cmdQuestions.CommandType = CommandType.StoredProcedure;
                        cmdQuestions.Parameters.AddWithValue("@exam_id", examId);

                        SqlDataAdapter da = new SqlDataAdapter(cmdQuestions);
                        da.Fill(dt);
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("No questions found for this course exam in the database.", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        examPanel.Controls.Clear();
                        return;
                    }

                    DisplayExamQuestions(dt);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Database Error: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void DisplayExamQuestions(DataTable dt)
        {
            examPanel.SuspendLayout();
            examPanel.Controls.Clear();

            var groupedQuestions = dt.AsEnumerable()
                .GroupBy(r => new {
                    QId = r.Field<int>("Question_Id"),
                    QText = r.Field<string>("Question_Text")
                });

            int qNum = 1;
            int cardWidth = examPanel.ClientSize.Width - 50;
            if (cardWidth < 600) cardWidth = 700;

            foreach (var qGroup in groupedQuestions)
            {
                GroupBox box = new GroupBox
                {
                    Text = $"Q{qNum++}: {qGroup.Key.QText}",
                    Font = new Font("Segoe UI", 11, FontStyle.Bold),
                    Width = cardWidth,
                    MinimumSize = new Size(cardWidth, 0),
                    AutoSize = true,
                    Margin = new Padding(10, 5, 10, 15),
                    Padding = new Padding(15),
                    Tag = qGroup.Key.QId
                };

                FlowLayoutPanel choicesPanel = new FlowLayoutPanel
                {
                    FlowDirection = FlowDirection.TopDown,
                    WrapContents = false,
                    AutoSize = true,
                    Width = cardWidth - 30,
                    MinimumSize = new Size(cardWidth - 30, 0),
                    Dock = DockStyle.Fill
                };

                foreach (DataRow row in qGroup)
                {
                    RadioButton rb = new RadioButton
                    {
                        Text = row.Field<string>("Choice_Text"),
                        Font = new Font("Segoe UI", 10, FontStyle.Regular),
                        AutoSize = true,
                        Margin = new Padding(5, 5, 5, 5),
                        Tag = row.Field<int>("Choice_Id")
                    };
                    choicesPanel.Controls.Add(rb);
                }

                box.Controls.Add(choicesPanel);
                examPanel.Controls.Add(box);
            }

            Button btnSubmit = new Button
            {
                Text = "Submit Exam",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                BackColor = Color.ForestGreen,
                ForeColor = Color.White,
                Size = new Size(200, 45),
                Margin = new Padding(10, 20, 10, 40),
                FlatStyle = FlatStyle.Flat
            };
            btnSubmit.Click += BtnSubmit_Click;

            examPanel.Controls.Add(btnSubmit);
            examPanel.ResumeLayout(true);
        }

        private void BtnSubmit_Click(object sender, EventArgs e)
        {
            var confirm = MessageBox.Show("Are you sure you want to submit your exam?", "Confirm Submission", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (confirm != DialogResult.Yes) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();

                    foreach (Control ctrl in examPanel.Controls)
                    {
                        if (ctrl is GroupBox qBox)
                        {
                            int qId = (int)qBox.Tag;
                            int? selectedChoiceId = null;

                            FlowLayoutPanel choicesPanel = qBox.Controls.OfType<FlowLayoutPanel>().FirstOrDefault();
                            if (choicesPanel != null)
                            {
                                foreach (RadioButton rb in choicesPanel.Controls.OfType<RadioButton>())
                                {
                                    if (rb.Checked)
                                    {
                                        selectedChoiceId = (int)rb.Tag;
                                        break;
                                    }
                                }
                            }

                            if (selectedChoiceId.HasValue)
                            {
                                using (SqlCommand cmdSave = new SqlCommand("sp_SaveStudentAnswer", conn))
                                {
                                    cmdSave.CommandType = CommandType.StoredProcedure;
                                    cmdSave.Parameters.AddWithValue("@studentExamId", currentStudentExamId);
                                    cmdSave.Parameters.AddWithValue("@questionid", qId);
                                    cmdSave.Parameters.AddWithValue("@choiceid", selectedChoiceId.Value);
                                    cmdSave.ExecuteNonQuery();
                                }
                            }
                        }
                    }

                    using (SqlCommand cmdGrade = new SqlCommand("sp_SubmitExamSafe", conn))
                    {
                        cmdGrade.CommandType = CommandType.StoredProcedure;
                        cmdGrade.Parameters.AddWithValue("@studentExamId", currentStudentExamId);

                        object finalScore = cmdGrade.ExecuteScalar();

                        MessageBox.Show($"Exam submitted successfully!\nYour Final Score: {finalScore}", "Result", MessageBoxButtons.OK, MessageBoxIcon.Information);

                        examPanel.Controls.Clear();
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error submitting exam: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
