<%@ Page Title="Completion Certificate" Language="C#"
    AutoEventWireup="true"
    Async="true"
    CodeBehind="Certificate.aspx.cs"
    Inherits="UniversityInternshipManagmentSystem.Student.CompletionCertificate" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Internship Completion Certificate</title>
    <style>
        :root {
            --green: #075340;
            --mint: #e9f4ef;
            --gold: #c49a43;
            --ink: #163d35;
            --muted: #60736e;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 28px;
            background: #eef3f1;
            color: var(--ink);
            font-family: "Segoe UI", Arial, sans-serif;
        }

        .toolbar {
            max-width: 1120px;
            margin: 0 auto 18px;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

            .toolbar a, .toolbar button {
                border: 0;
                border-radius: 8px;
                padding: 11px 17px;
                background: var(--green);
                color: #fff;
                font: inherit;
                font-weight: 600;
                text-decoration: none;
                cursor: pointer;
            }

            .toolbar a {
                background: #fff;
                color: var(--green);
                border: 1px solid #cbd9d4;
            }

        .certificate {
            position: relative;
            max-width: 1120px;
            min-height: 730px;
            margin: auto;
            padding: 58px 76px;
            overflow: hidden;
            border: 12px solid var(--green);
            outline: 2px solid var(--gold);
            outline-offset: -22px;
            background: #fff;
            text-align: center;
            box-shadow: 0 18px 55px rgba(18, 58, 48, .12);
        }

            .certificate:before, .certificate:after {
                content: "";
                position: absolute;
                width: 180px;
                height: 180px;
                border: 1px solid rgba(196,154,67,.45);
                transform: rotate(45deg);
            }

            .certificate:before {
                top: -125px;
                left: -125px;
            }

            .certificate:after {
                right: -125px;
                bottom: -125px;
            }

        .seal {
            width: 66px;
            height: 66px;
            margin: 0 auto 12px;
            display: grid;
            place-items: center;
            border: 2px solid var(--gold);
            border-radius: 50%;
            color: var(--green);
            font-family: Georgia, serif;
            font-size: 21px;
            font-weight: 700;
        }

            .seal span {
                color: var(--gold);
            }

        .university {
            margin: 0;
            color: var(--green);
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 2px;
            text-transform: uppercase;
        }

        .rule {
            width: 120px;
            height: 2px;
            margin: 20px auto 26px;
            background: var(--gold);
        }

        h1 {
            margin: 0;
            color: var(--green);
            font-family: Georgia, "Times New Roman", serif;
            font-size: clamp(34px, 5vw, 54px);
            font-weight: 500;
        }

        .intro {
            margin: 16px 0 8px;
            color: var(--muted);
            font-family: Georgia, serif;
            font-size: 19px;
        }

        .student {
            margin: 8px 0 12px;
            color: var(--green);
            font-family: Georgia, "Times New Roman", serif;
            font-size: clamp(30px, 4.5vw, 46px);
            font-weight: 700;
        }

        .major {
            margin: 0;
            color: var(--muted);
            font-size: 16px;
        }

        .statement {
            max-width: 760px;
            margin: 26px auto 25px;
            color: #455d57;
            font-size: 17px;
            line-height: 1.7;
        }

        .details {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            max-width: 840px;
            margin: 0 auto;
            text-align: left;
        }

        .detail {
            min-height: 78px;
            padding: 13px 15px;
            border: 1px solid #dce7e2;
            border-radius: 8px;
            background: #fbfdfc;
        }

            .detail span {
                display: block;
                margin-bottom: 7px;
                color: var(--muted);
                font-size: 11px;
                font-weight: 700;
                letter-spacing: .8px;
                text-transform: uppercase;
            }

            .detail strong {
                display: block;
                color: var(--green);
                font-size: 15px;
                overflow-wrap: anywhere;
            }

        .footer {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            max-width: 840px;
            margin: 42px auto 0;
            gap: 30px;
        }

        .signature {
            min-width: 220px;
            padding-top: 11px;
            border-top: 1px solid #8fa69e;
            color: var(--muted);
            font-size: 12px;
        }

        .cert-number {
            color: var(--muted);
            font-size: 12px;
            text-align: right;
        }

        .error {
            max-width: 720px;
            margin: 10vh auto;
            padding: 28px;
            border: 1px solid #f0aab0;
            border-radius: 12px;
            background: #fff2f3;
            color: #842029;
            text-align: center;
        }

        @media (max-width: 700px) {
            body {
                padding: 12px;
            }

            .certificate {
                min-height: 0;
                padding: 46px 28px;
                border-width: 8px;
                outline-offset: -16px;
            }

            .details {
                grid-template-columns: repeat(2, 1fr);
            }

            .footer {
                margin-top: 30px;
            }
        }

        @media (max-width: 460px) {
            .details {
                grid-template-columns: 1fr;
            }

            .footer {
                align-items: stretch;
                flex-direction: column;
            }

            .cert-number {
                text-align: left;
            }
        }

        @page {
            size: A4 landscape;
            margin: 8mm;
        }

        @media print {
            body {
                padding: 0;
                background: #fff;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }

            .toolbar {
                display: none !important;
            }

            .certificate {
                width: 100%;
                max-width: none;
                min-height: 185mm;
                padding: 36px 60px;
                box-shadow: none;
                break-inside: avoid;
            }

            .error {
                margin: 0;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:Panel ID="pnlCertificate" runat="server" Visible="false">
            <nav class="toolbar" aria-label="Certificate actions">
                <a href="MyProgress.aspx">Back to progress</a>
                <button type="button" onclick="window.print()">Print / Save as PDF</button>
            </nav>
            <main class="certificate">
                <div class="seal" aria-hidden="true">U<span>J</span></div>
                <p class="university">The University of Jordan</p>
                <div class="rule"></div>
                <h1>Certificate of Completion</h1>
                <p class="intro">This certificate is proudly presented to</p>
                <p class="student">
                    <asp:Literal ID="litStudent" runat="server" /></p>
                <p class="major">
                    <asp:Literal ID="litMajor" runat="server" /></p>
                <p class="statement">For successfully completing the internship training program at <strong>
                    <asp:Literal ID="litCompany" runat="server" /></strong>. The training details below are based on the records approved by the university training coordinator.</p>
                <section class="details" aria-label="Training details">
                    <div class="detail"><span>Training company</span><strong><asp:Literal ID="litCompanyDetail" runat="server" /></strong></div>
                    <div class="detail"><span>Opportunity</span><strong><asp:Literal ID="litOpportunity" runat="server" /></strong></div>
                    <div class="detail"><span>Training period</span><strong><asp:Literal ID="litPeriod" runat="server" /></strong></div>
                    <div class="detail"><span>Completed weeks</span><strong><asp:Literal ID="litWeeks" runat="server" /></strong></div>
                    <div class="detail"><span>Approved training hours</span><strong><asp:Literal ID="litHours" runat="server" /></strong></div>
                    <div class="detail"><span>Approval date</span><strong><asp:Literal ID="litApprovalDate" runat="server" /></strong></div>
                </section>
                <footer class="footer">
                    <div class="signature">University Training Coordinator</div>
                    <div class="cert-number">Certificate No.<br />
                        <strong>
                            <asp:Literal ID="litCertificateId" runat="server" /></strong></div>
                </footer>
            </main>
        </asp:Panel>
        <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="error" role="alert">
            <h1>Certificate unavailable</h1>
            <p>
                <asp:Literal ID="litError" runat="server" /></p>
            <a href="MyProgress.aspx">Return to My Progress</a>
        </asp:Panel>
    </form>
    <script>
        if (new URLSearchParams(window.location.search).get("print") === "1") {
            window.addEventListener("load", function () { window.setTimeout(function () { window.print(); }, 300); });
        }
    </script>
</body>
</html>
