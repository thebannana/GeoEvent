using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LocationService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Continents",
                columns: table => new
                {
                    ContinentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ContinentName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ContinentCode = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Continents", x => x.ContinentId);
                });

            migrationBuilder.CreateTable(
                name: "Countries",
                columns: table => new
                {
                    CountryId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CountryName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CountryCodeAlpha2 = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    CountryCodeAlpha3 = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false),
                    CountryCodeNumeric = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    ContinentId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Countries", x => x.CountryId);
                    table.ForeignKey(
                        name: "FK_Countries_Continents_ContinentId",
                        column: x => x.ContinentId,
                        principalTable: "Continents",
                        principalColumn: "ContinentId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "AdministrativeDivisions",
                columns: table => new
                {
                    DivisionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CountryId = table.Column<int>(type: "int", nullable: true),
                    ParentDivisionId = table.Column<int>(type: "int", nullable: true),
                    DivisionName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    DivisionCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    DivisionType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Level = table.Column<int>(type: "int", nullable: false),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdministrativeDivisions", x => x.DivisionId);
                    table.ForeignKey(
                        name: "FK_AdministrativeDivisions_AdministrativeDivisions_ParentDivisionId",
                        column: x => x.ParentDivisionId,
                        principalTable: "AdministrativeDivisions",
                        principalColumn: "DivisionId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AdministrativeDivisions_Countries_CountryId",
                        column: x => x.CountryId,
                        principalTable: "Countries",
                        principalColumn: "CountryId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    CityId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CityName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    NormalizedName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    DivisionId = table.Column<int>(type: "int", nullable: true),
                    CountryId = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.CityId);
                    table.ForeignKey(
                        name: "FK_Cities_AdministrativeDivisions_DivisionId",
                        column: x => x.DivisionId,
                        principalTable: "AdministrativeDivisions",
                        principalColumn: "DivisionId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Cities_Countries_CountryId",
                        column: x => x.CountryId,
                        principalTable: "Countries",
                        principalColumn: "CountryId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PostalCodes",
                columns: table => new
                {
                    PostalCodeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostalCodes", x => x.PostalCodeId);
                    table.ForeignKey(
                        name: "FK_PostalCodes_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "CityId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_CountryId",
                table: "AdministrativeDivisions",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_CountryId_Level",
                table: "AdministrativeDivisions",
                columns: new[] { "CountryId", "Level" });

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_DivisionCode",
                table: "AdministrativeDivisions",
                column: "DivisionCode");

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_IsActive",
                table: "AdministrativeDivisions",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_Level",
                table: "AdministrativeDivisions",
                column: "Level");

            migrationBuilder.CreateIndex(
                name: "IX_AdministrativeDivisions_ParentDivisionId",
                table: "AdministrativeDivisions",
                column: "ParentDivisionId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId",
                table: "Cities",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId_IsActive",
                table: "Cities",
                columns: new[] { "CountryId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Cities_DivisionId",
                table: "Cities",
                column: "DivisionId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_IsActive",
                table: "Cities",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_NormalizedName",
                table: "Cities",
                column: "NormalizedName");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_NormalizedName_CountryId",
                table: "Cities",
                columns: new[] { "NormalizedName", "CountryId" });

            migrationBuilder.CreateIndex(
                name: "IX_Continents_ContinentCode",
                table: "Continents",
                column: "ContinentCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Continents_ContinentName",
                table: "Continents",
                column: "ContinentName");

            migrationBuilder.CreateIndex(
                name: "IX_Countries_ContinentId",
                table: "Countries",
                column: "ContinentId");

            migrationBuilder.CreateIndex(
                name: "IX_Countries_CountryCodeAlpha2",
                table: "Countries",
                column: "CountryCodeAlpha2",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Countries_CountryCodeAlpha3",
                table: "Countries",
                column: "CountryCodeAlpha3",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Countries_CountryCodeNumeric",
                table: "Countries",
                column: "CountryCodeNumeric",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Countries_CountryName",
                table: "Countries",
                column: "CountryName");

            migrationBuilder.CreateIndex(
                name: "IX_Countries_IsActive",
                table: "Countries",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_PostalCodes_CityId",
                table: "PostalCodes",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_PostalCodes_Code",
                table: "PostalCodes",
                column: "Code");

            migrationBuilder.CreateIndex(
                name: "IX_PostalCodes_Code_CityId",
                table: "PostalCodes",
                columns: new[] { "Code", "CityId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PostalCodes");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "AdministrativeDivisions");

            migrationBuilder.DropTable(
                name: "Countries");

            migrationBuilder.DropTable(
                name: "Continents");
        }
    }
}
