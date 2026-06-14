using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateUserSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_UserRatings_Value",
                table: "UserRatings");

            migrationBuilder.AddCheckConstraint(
                name: "CK_UserRating_Value",
                table: "UserRatings",
                sql: "[Value] >= 1 AND [Value] <= 5");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_UserRating_Value",
                table: "UserRatings");

            migrationBuilder.AddCheckConstraint(
                name: "CK_UserRatings_Value",
                table: "UserRatings",
                sql: "[Value] >= 1 AND [Value] <= 5");
        }
    }
}
