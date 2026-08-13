using Microsoft.Reporting.WinForms;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace ReportsForm
{
    public partial class CourseStatsForm : Form
    {
        private ReportViewer reportViewerStats;
        private string connString = @"Server=localhost;Database=ExamManagementDB;Trusted_Connection=True;TrustServerCertificate=True;";

        public CourseStatsForm()
        {
            InitializeComponent();

            reportViewerStats = new ReportViewer();
            reportViewerStats.Dock = DockStyle.Fill;
            this.Controls.Add(reportViewerStats);

            LoadCourseStatsReport();
        }

        private void CourseStatsForm_Load(object sender, EventArgs e)
        {
            LoadCourseStatsReport();
        }

        private void LoadCourseStatsReport()
        {
            this.WindowState = FormWindowState.Maximized;

            try
            {
                DataTable dt = new DataTable();
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    string query = "SELECT * FROM v_CourseExamStatistics";
                    SqlDataAdapter da = new SqlDataAdapter(query, conn);
                    da.Fill(dt);
                }

                reportViewerStats.LocalReport.DataSources.Clear();
                reportViewerStats.LocalReport.ReportPath = @"Reports\Course Exam Statistics Report.rdl";

                ReportDataSource rds = new ReportDataSource("DataSet1", dt);
                reportViewerStats.LocalReport.DataSources.Add(rds);

                reportViewerStats.RefreshReport();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading statistics report: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void CourseStatsForm_Load_1(object sender, EventArgs e)
        {

        }
    }
}