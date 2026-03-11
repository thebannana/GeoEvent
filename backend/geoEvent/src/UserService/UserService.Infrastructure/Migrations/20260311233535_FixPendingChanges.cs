using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixPendingChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences");

            migrationBuilder.AddColumn<string>(
                name: "EmailVerificationToken",
                table: "Users",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerificationTokenExpiresAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerifiedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordResetToken",
                table: "Users",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PasswordResetTokenExpiresAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Reports",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "ResolvedAt",
                table: "Reports",
                type: "datetime2",
                nullable: true);

            // Drop index first, then drop old int column, re-add as Guid
            migrationBuilder.DropIndex(
                name: "IX_ActivityLogs_SessionId",
                table: "ActivityLogs");

            migrationBuilder.DropColumn(
                name: "SessionId",
                table: "ActivityLogs");

            migrationBuilder.AddColumn<Guid>(
                name: "SessionId",
                table: "ActivityLogs",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_SessionId",
                table: "ActivityLogs",
                column: "SessionId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_EmailVerificationToken",
                table: "Users",
                column: "EmailVerificationToken",
                filter: "[EmailVerificationToken] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Users_PasswordResetToken",
                table: "Users",
                column: "PasswordResetToken",
                filter: "[PasswordResetToken] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences",
                columns: new[] { "UserId", "SegmentId", "GenreId" },
                unique: true,
                filter: "[UserId] IS NOT NULL AND [SegmentId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_CreatedAt",
                table: "Reports",
                column: "CreatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_EmailVerificationToken",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_PasswordResetToken",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_Reports_CreatedAt",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "EmailVerificationToken",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "EmailVerificationTokenExpiresAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "EmailVerifiedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PasswordResetToken",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenExpiresAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "ResolvedAt",
                table: "Reports");

            // Reverse: drop Guid column, re-add as int
            migrationBuilder.DropIndex(
                name: "IX_ActivityLogs_SessionId",
                table: "ActivityLogs");

            migrationBuilder.DropColumn(
                name: "SessionId",
                table: "ActivityLogs");

            migrationBuilder.AddColumn<int>(
                name: "SessionId",
                table: "ActivityLogs",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_SessionId",
                table: "ActivityLogs",
                column: "SessionId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences",
                columns: new[] { "UserId", "SegmentId", "GenreId" },
                unique: true,
                filter: "[UserId] IS NOT NULL");
        }
    }
}
