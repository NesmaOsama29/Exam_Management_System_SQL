using Microsoft.Reporting.WinForms;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace ReportsForm
{
    public partial class StudentExamForm : Form
    {
        private ReportViewer reportViewerResults;
        private string connString = @"Server=localhost;Database=ExamManagementDB;Trusted_Connection=True;TrustServerCertificate=True;";

        public StudentExamForm()
        {
            InitializeComponent();

            reportViewerResults = new ReportViewer();
            reportViewerResults.Dock = DockStyle.Fill;
            this.Controls.Add(reportViewerResults);
        }

        private void Form1_Load_1(object sender, EventArgs e)
        {
            LoadStudentResultsReport();
        }

        private void StudentExamForm_Load(object sender, EventArgs e)
        {
            LoadStudentResultsReport();
        }

        private void LoadStudentResultsReport()
        {
            this.WindowState = FormWindowState.Maximized;

            try
            {
                DataTable dt = new DataTable();
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    string query = "SELECT * FROM v_StudentExamResults";
                    SqlDataAdapter da = new SqlDataAdapter(query, conn);
                    da.Fill(dt);
                }

                reportViewerResults.LocalReport.DataSources.Clear();
                reportViewerResults.LocalReport.ReportPath = @"Reports\Student Exam Results Report.rdl";
                ReportDataSource rds = new ReportDataSource("DataSet1", dt);
                reportViewerResults.LocalReport.DataSources.Add(rds);

                reportViewerResults.RefreshReport();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading student exam results report: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}