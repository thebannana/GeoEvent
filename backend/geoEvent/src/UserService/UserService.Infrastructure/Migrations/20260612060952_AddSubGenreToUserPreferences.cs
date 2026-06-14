using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSubGenreToUserPreferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences");

            migrationBuilder.AlterColumn<DateTime>(
                name: "LastUpdated",
                table: "UserPreferences",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<int>(
                name: "SubGenreId",
                table: "UserPreferences",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_SubGenreId",
                table: "UserPreferences",
                column: "SubGenreId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId_SubGenreId",
                table: "UserPreferences",
                columns: new[] { "UserId", "SegmentId", "GenreId", "SubGenreId" },
                unique: true,
                filter: "[UserId] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_SubGenreId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId_SubGenreId",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "SubGenreId",
                table: "UserPreferences");

            migrationBuilder.AlterColumn<DateTime>(
                name: "LastUpdated",
                table: "UserPreferences",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences",
                columns: new[] { "UserId", "SegmentId", "GenreId" },
                unique: true,
                filter: "[UserId] IS NOT NULL AND [SegmentId] IS NOT NULL");
        }
    }
}
