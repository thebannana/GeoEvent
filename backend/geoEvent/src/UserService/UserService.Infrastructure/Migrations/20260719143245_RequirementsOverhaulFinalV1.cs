using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RequirementsOverhaulFinalV1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "TargetId",
                table: "Reports",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ResolutionNote",
                table: "Reports",
                type: "nvarchar(4000)",
                maxLength: 4000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "ReporterId",
                table: "Reports",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ModeratorAction",
                table: "Reports",
                type: "nvarchar(4000)",
                maxLength: 4000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Reports",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(2000)",
                oldMaxLength: 2000);

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId_Status",
                table: "Reports",
                columns: new[] { "ReporterId", "TargetType", "TargetId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Reports_Status_CreatedAt",
                table: "Reports",
                columns: new[] { "Status", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Reports_TargetId",
                table: "Reports",
                column: "TargetId");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Report_Status_Valid",
                table: "Reports",
                sql: "[Status] IN ('Pending', 'UnderReview', 'Resolved', 'Dismissed')");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Report_TargetId_Positive",
                table: "Reports",
                sql: "[TargetId] > 0");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Report_TargetType_Valid",
                table: "Reports",
                sql: "[TargetType] IN ('User', 'Event', 'Comment', 'Review')");

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Users_TargetId",
                table: "Reports",
                column: "TargetId",
                principalTable: "Users",
                principalColumn: "PersonId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reports_Users_TargetId",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_ReporterId_TargetType_TargetId_Status",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_Status_CreatedAt",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Reports_TargetId",
                table: "Reports");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Report_Status_Valid",
                table: "Reports");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Report_TargetId_Positive",
                table: "Reports");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Report_TargetType_Valid",
                table: "Reports");

            migrationBuilder.AlterColumn<int>(
                name: "TargetId",
                table: "Reports",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "ResolutionNote",
                table: "Reports",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(4000)",
                oldMaxLength: 4000,
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "ReporterId",
                table: "Reports",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "ModeratorAction",
                table: "Reports",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(4000)",
                oldMaxLength: 4000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Reports",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(2000)",
                oldMaxLength: 2000,
                oldNullable: true);
        }
    }
}
