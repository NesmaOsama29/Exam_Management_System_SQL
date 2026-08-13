using System;
using System.Drawing;
using System.Windows.Forms;

namespace ReportsForm
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
            ApplyModernUI();
        }

        private void ApplyModernUI()
        {
           
            this.Text = "Exam Management System - Dashboard";
            this.Size = new Size(1100, 650);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(244, 246, 249); 
            this.Controls.Clear(); 

            Panel headerPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 100,
                BackColor = Color.FromArgb(28, 41, 56) 
            };

            Label lblTitle = new Label
            {
                Text = "Student & Exam Management Portal",
                Font = new Font("Segoe UI", 18, FontStyle.Bold),
                ForeColor = Color.White,
                AutoSize = true,
                Location = new Point(30, 20)
            };

            Label lblSubTitle = new Label
            {
                Text = "Welcome! Select an option below to navigate through the system.",
                Font = new Font("Segoe UI", 10, FontStyle.Regular),
                ForeColor = Color.FromArgb(176, 190, 197),
                AutoSize = true,
                Location = new Point(32, 58)
            };

            headerPanel.Controls.Add(lblTitle);
            headerPanel.Controls.Add(lblSubTitle);

     
            FlowLayoutPanel cardsPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(40, 50, 40, 40),
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = true
            };

            Panel card1 = CreateDashboardCard("Exam Results", "View and filter student exam scores and performance.", Color.FromArgb(52, 152, 219), (s, e) => OpenForm(new StudentExamForm()));
            Panel card2 = CreateDashboardCard("Course Stats", "Analyze course analytics, statistics, and reports.", Color.FromArgb(155, 89, 182), (s, e) => OpenForm(new CourseStatsForm()));
            Panel card3 = CreateDashboardCard("Take Exam", "Start and take course exams for students.", Color.FromArgb(46, 204, 113), (s, e) => OpenForm(new TakeExamForm()));

            cardsPanel.Controls.Add(card1);
            cardsPanel.Controls.Add(card2);
            cardsPanel.Controls.Add(card3);

            this.Controls.Add(cardsPanel);
            this.Controls.Add(headerPanel);
        }

        private Panel CreateDashboardCard(string title, string description, Color accentColor, EventHandler onClick)
        {
            Panel card = new Panel
            {
                Size = new Size(290, 220),
                Margin = new Padding(20),
                BackColor = Color.White,
                Cursor = Cursors.Hand
            };

            Panel topBar = new Panel
            {
                Dock = DockStyle.Top,
                Height = 6,
                BackColor = accentColor
            };

            Label lblTitle = new Label
            {
                Text = title,
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = Color.FromArgb(44, 62, 80),
                Location = new Point(20, 25),
                AutoSize = true
            };

            Label lblDesc = new Label
            {
                Text = description,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Regular),
                ForeColor = Color.FromArgb(127, 140, 141),
                Location = new Point(20, 65),
                Size = new Size(250, 70)
            };

            Button btnAction = new Button
            {
                Text = "Open Module  ➔",
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                ForeColor = accentColor,
                BackColor = Color.FromArgb(245, 247, 250),
                FlatStyle = FlatStyle.Flat,
                Size = new Size(250, 38),
                Location = new Point(20, 155),
                Cursor = Cursors.Hand
            };
            btnAction.FlatAppearance.BorderSize = 0;

           
            card.Click += onClick;
            lblTitle.Click += onClick;
            lblDesc.Click += onClick;
            btnAction.Click += onClick;

        
            card.MouseEnter += (s, e) => { card.BackColor = Color.FromArgb(250, 252, 255); };
            card.MouseLeave += (s, e) => { card.BackColor = Color.White; };

            card.Controls.Add(topBar);
            card.Controls.Add(lblTitle);
            card.Controls.Add(lblDesc);
            card.Controls.Add(btnAction);

            return card;
        }

        private void OpenForm(Form targetForm)
        {
            targetForm.ShowDialog();
        }
    }
}
