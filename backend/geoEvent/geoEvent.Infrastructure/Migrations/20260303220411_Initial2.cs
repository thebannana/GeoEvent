using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace geoEvent.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Initial2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ActivityLogs_Categories_CategoryId",
                table: "ActivityLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_Categories_CategoryId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_UserPreferences_Categories_CategoryId",
                table: "UserPreferences");

            migrationBuilder.DropTable(
                name: "Categories");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_CategoryId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_Events_CategoryId_StartDateTime",
                table: "Events");

            migrationBuilder.RenameColumn(
                name: "CategoryId",
                table: "UserPreferences",
                newName: "SegmentId");

            migrationBuilder.RenameIndex(
                name: "IX_UserPreferences_CategoryId",
                table: "UserPreferences",
                newName: "IX_UserPreferences_SegmentId");

            migrationBuilder.RenameColumn(
                name: "CategoryId",
                table: "Events",
                newName: "SubGenreId");

            migrationBuilder.RenameIndex(
                name: "IX_Events_CategoryId",
                table: "Events",
                newName: "IX_Events_SubGenreId");

            migrationBuilder.RenameColumn(
                name: "CategoryId",
                table: "ActivityLogs",
                newName: "SegmentId");

            migrationBuilder.RenameIndex(
                name: "IX_ActivityLogs_CategoryId",
                table: "ActivityLogs",
                newName: "IX_ActivityLogs_SegmentId");

            migrationBuilder.AddColumn<string>(
                name: "Locale",
                table: "Venues",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TimeZone",
                table: "Venues",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AlterColumn<double>(
                name: "Score",
                table: "UserPreferences",
                type: "float",
                nullable: false,
                defaultValue: 0.0,
                oldClrType: typeof(double),
                oldType: "float");

            migrationBuilder.AddColumn<int>(
                name: "GenreId",
                table: "UserPreferences",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PriceZoneId",
                table: "Tickets",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GenreId",
                table: "Events",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Locale",
                table: "Events",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true,
                defaultValue: "bs-BA");

            migrationBuilder.AddColumn<string>(
                name: "PromoterName",
                table: "Events",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SegmentId",
                table: "Events",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GenreId",
                table: "ActivityLogs",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PriceZones",
                columns: table => new
                {
                    PriceZoneId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VenueId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PriceZones", x => x.PriceZoneId);
                    table.ForeignKey(
                        name: "FK_PriceZones_Venues_VenueId",
                        column: x => x.VenueId,
                        principalTable: "Venues",
                        principalColumn: "VenueId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Segments",
                columns: table => new
                {
                    SegmentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IconUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Color = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Segments", x => x.SegmentId);
                });

            migrationBuilder.CreateTable(
                name: "Genres",
                columns: table => new
                {
                    GenreId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    SegmentId = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Genres", x => x.GenreId);
                    table.ForeignKey(
                        name: "FK_Genres_Segments_SegmentId",
                        column: x => x.SegmentId,
                        principalTable: "Segments",
                        principalColumn: "SegmentId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SubGenres",
                columns: table => new
                {
                    SubGenreId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    GenreId = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubGenres", x => x.SubGenreId);
                    table.ForeignKey(
                        name: "FK_SubGenres_Genres_GenreId",
                        column: x => x.GenreId,
                        principalTable: "Genres",
                        principalColumn: "GenreId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_GenreId",
                table: "UserPreferences",
                column: "GenreId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences",
                columns: new[] { "UserId", "SegmentId", "GenreId" },
                unique: true,
                filter: "[UserId] IS NOT NULL AND [SegmentId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_PriceZoneId",
                table: "Tickets",
                column: "PriceZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_GenreId",
                table: "Events",
                column: "GenreId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_GenreId_StartDateTime",
                table: "Events",
                columns: new[] { "GenreId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_SegmentId",
                table: "Events",
                column: "SegmentId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_SegmentId_StartDateTime",
                table: "Events",
                columns: new[] { "SegmentId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_GenreId",
                table: "ActivityLogs",
                column: "GenreId");

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_SegmentId_CreatedAt",
                table: "ActivityLogs",
                columns: new[] { "SegmentId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_UserId_CreatedAt",
                table: "ActivityLogs",
                columns: new[] { "UserId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Genres_IsActive",
                table: "Genres",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Genres_Name",
                table: "Genres",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_Genres_SegmentId",
                table: "Genres",
                column: "SegmentId");

            migrationBuilder.CreateIndex(
                name: "IX_Genres_SegmentId_IsActive",
                table: "Genres",
                columns: new[] { "SegmentId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_PriceZones_IsActive",
                table: "PriceZones",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_PriceZones_VenueId",
                table: "PriceZones",
                column: "VenueId");

            migrationBuilder.CreateIndex(
                name: "IX_PriceZones_VenueId_IsActive",
                table: "PriceZones",
                columns: new[] { "VenueId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Segments_IsActive",
                table: "Segments",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Segments_Name",
                table: "Segments",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SubGenres_GenreId",
                table: "SubGenres",
                column: "GenreId");

            migrationBuilder.CreateIndex(
                name: "IX_SubGenres_GenreId_IsActive",
                table: "SubGenres",
                columns: new[] { "GenreId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_SubGenres_IsActive",
                table: "SubGenres",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_SubGenres_Name",
                table: "SubGenres",
                column: "Name");

            migrationBuilder.AddForeignKey(
                name: "FK_ActivityLogs_Genres_GenreId",
                table: "ActivityLogs",
                column: "GenreId",
                principalTable: "Genres",
                principalColumn: "GenreId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_ActivityLogs_Segments_SegmentId",
                table: "ActivityLogs",
                column: "SegmentId",
                principalTable: "Segments",
                principalColumn: "SegmentId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events",
                column: "GenreId",
                principalTable: "Genres",
                principalColumn: "GenreId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events",
                column: "SegmentId",
                principalTable: "Segments",
                principalColumn: "SegmentId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events",
                column: "SubGenreId",
                principalTable: "SubGenres",
                principalColumn: "SubGenreId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Tickets_PriceZones_PriceZoneId",
                table: "Tickets",
                column: "PriceZoneId",
                principalTable: "PriceZones",
                principalColumn: "PriceZoneId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserPreferences_Genres_GenreId",
                table: "UserPreferences",
                column: "GenreId",
                principalTable: "Genres",
                principalColumn: "GenreId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserPreferences_Segments_SegmentId",
                table: "UserPreferences",
                column: "SegmentId",
                principalTable: "Segments",
                principalColumn: "SegmentId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ActivityLogs_Genres_GenreId",
                table: "ActivityLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_ActivityLogs_Segments_SegmentId",
                table: "ActivityLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Tickets_PriceZones_PriceZoneId",
                table: "Tickets");

            migrationBuilder.DropForeignKey(
                name: "FK_UserPreferences_Genres_GenreId",
                table: "UserPreferences");

            migrationBuilder.DropForeignKey(
                name: "FK_UserPreferences_Segments_SegmentId",
                table: "UserPreferences");

            migrationBuilder.DropTable(
                name: "PriceZones");

            migrationBuilder.DropTable(
                name: "SubGenres");

            migrationBuilder.DropTable(
                name: "Genres");

            migrationBuilder.DropTable(
                name: "Segments");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_GenreId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId_SegmentId_GenreId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_Tickets_PriceZoneId",
                table: "Tickets");

            migrationBuilder.DropIndex(
                name: "IX_Events_GenreId",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_GenreId_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_SegmentId",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_SegmentId_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_ActivityLogs_GenreId",
                table: "ActivityLogs");

            migrationBuilder.DropIndex(
                name: "IX_ActivityLogs_SegmentId_CreatedAt",
                table: "ActivityLogs");

            migrationBuilder.DropIndex(
                name: "IX_ActivityLogs_UserId_CreatedAt",
                table: "ActivityLogs");

            migrationBuilder.DropColumn(
                name: "Locale",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "TimeZone",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "GenreId",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "PriceZoneId",
                table: "Tickets");

            migrationBuilder.DropColumn(
                name: "GenreId",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "Locale",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "PromoterName",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "SegmentId",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "GenreId",
                table: "ActivityLogs");

            migrationBuilder.RenameColumn(
                name: "SegmentId",
                table: "UserPreferences",
                newName: "CategoryId");

            migrationBuilder.RenameIndex(
                name: "IX_UserPreferences_SegmentId",
                table: "UserPreferences",
                newName: "IX_UserPreferences_CategoryId");

            migrationBuilder.RenameColumn(
                name: "SubGenreId",
                table: "Events",
                newName: "CategoryId");

            migrationBuilder.RenameIndex(
                name: "IX_Events_SubGenreId",
                table: "Events",
                newName: "IX_Events_CategoryId");

            migrationBuilder.RenameColumn(
                name: "SegmentId",
                table: "ActivityLogs",
                newName: "CategoryId");

            migrationBuilder.RenameIndex(
                name: "IX_ActivityLogs_SegmentId",
                table: "ActivityLogs",
                newName: "IX_ActivityLogs_CategoryId");

            migrationBuilder.AlterColumn<double>(
                name: "Score",
                table: "UserPreferences",
                type: "float",
                nullable: false,
                oldClrType: typeof(double),
                oldType: "float",
                oldDefaultValue: 0.0);

            migrationBuilder.CreateTable(
                name: "Categories",
                columns: table => new
                {
                    CategoryId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ParentCategoryId = table.Column<int>(type: "int", nullable: true),
                    CategoryName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Color = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    IconUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Categories", x => x.CategoryId);
                    table.ForeignKey(
                        name: "FK_Categories_Categories_ParentCategoryId",
                        column: x => x.ParentCategoryId,
                        principalTable: "Categories",
                        principalColumn: "CategoryId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId_CategoryId",
                table: "UserPreferences",
                columns: new[] { "UserId", "CategoryId" },
                unique: true,
                filter: "[UserId] IS NOT NULL AND [CategoryId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Events_CategoryId_StartDateTime",
                table: "Events",
                columns: new[] { "CategoryId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_Categories_CategoryName",
                table: "Categories",
                column: "CategoryName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Categories_ParentCategoryId",
                table: "Categories",
                column: "ParentCategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_ActivityLogs_Categories_CategoryId",
                table: "ActivityLogs",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "CategoryId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Categories_CategoryId",
                table: "Events",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "CategoryId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserPreferences_Categories_CategoryId",
                table: "UserPreferences",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "CategoryId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
