using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LocationService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCommentLikes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_PostalCodes_Code",
                table: "PostalCodes");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CountryId_IsActive",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Cities_NormalizedName_CountryId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_AdministrativeDivisions_Level",
                table: "AdministrativeDivisions");

            migrationBuilder.CreateIndex(
                name: "IX_PostalCodes_Code",
                table: "PostalCodes",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CityName",
                table: "Cities",
                column: "CityName");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_DivisionId_IsActive",
                table: "Cities",
                columns: new[] { "DivisionId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_Level_DivisionType",
                table: "AdministrativeDivisions",
                columns: new[] { "Level", "DivisionType" });

            migrationBuilder.AddForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "CountryId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_PostalCodes_Code",
                table: "PostalCodes");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CityName",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Cities_DivisionId_IsActive",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_AdministrativeDivisions_Level_DivisionType",
                table: "AdministrativeDivisions");

            migrationBuilder.CreateIndex(
                name: "IX_PostalCodes_Code",
                table: "PostalCodes",
                column: "Code");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId_IsActive",
                table: "Cities",
                columns: new[] { "CountryId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Cities_NormalizedName_CountryId",
                table: "Cities",
                columns: new[] { "NormalizedName", "CountryId" });

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_Level",
                table: "AdministrativeDivisions",
                column: "Level");

            migrationBuilder.AddForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "CountryId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
