using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserRatings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ModeratorAction",
                table: "Reports",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResolutionNote",
                table: "Reports",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserRatings",
                columns: table => new
                {
                    RatingId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RaterId = table.Column<int>(type: "int", nullable: false),
                    RatedUserId = table.Column<int>(type: "int", nullable: false),
                    Value = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRatings", x => x.RatingId);
                    table.CheckConstraint("CK_UserRatings_Value", "[Value] >= 1 AND [Value] <= 5");
                    table.ForeignKey(
                        name: "FK_UserRatings_Users_RatedUserId",
                        column: x => x.RatedUserId,
                        principalTable: "Users",
                        principalColumn: "PersonId");
                    table.ForeignKey(
                        name: "FK_UserRatings_Users_RaterId",
                        column: x => x.RaterId,
                        principalTable: "Users",
                        principalColumn: "PersonId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_RatedUserId",
                table: "UserRatings",
                column: "RatedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_RaterId_RatedUserId",
                table: "UserRatings",
                columns: new[] { "RaterId", "RatedUserId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserRatings");

            migrationBuilder.DropColumn(
                name: "ModeratorAction",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "ResolutionNote",
                table: "Reports");
        }
    }
}
