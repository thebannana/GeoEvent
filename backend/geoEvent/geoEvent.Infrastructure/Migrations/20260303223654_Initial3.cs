using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace geoEvent.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Initial3 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ConsentGivenAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ConsentVersion",
                table: "Users",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FailedLoginAttempts",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLoginAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LastLoginIp",
                table: "Users",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LockoutUntil",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "People",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "People",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "People",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Currency",
                table: "PaymentDetails",
                type: "nvarchar(3)",
                maxLength: 3,
                nullable: true,
                defaultValue: "EUR");

            migrationBuilder.AddColumn<string>(
                name: "TransactionId",
                table: "PaymentDetails",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    TokenId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TokenHash = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RevokedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DeviceInfo = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.TokenId);
                    table.ForeignKey(
                        name: "FK_RefreshTokens_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "PersonId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_LockoutUntil",
                table: "Users",
                column: "LockoutUntil");

            migrationBuilder.CreateIndex(
                name: "IX_People_IsDeleted",
                table: "People",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_TransactionId",
                table: "PaymentDetails",
                column: "TransactionId",
                unique: true,
                filter: "[TransactionId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_ExpiresAt",
                table: "RefreshTokens",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_RevokedAt",
                table: "RefreshTokens",
                column: "RevokedAt");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_TokenHash",
                table: "RefreshTokens",
                column: "TokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId",
                table: "RefreshTokens",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId_RevokedAt",
                table: "RefreshTokens",
                columns: new[] { "UserId", "RevokedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_Users_LockoutUntil",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_People_IsDeleted",
                table: "People");

            migrationBuilder.DropIndex(
                name: "IX_PaymentDetails_TransactionId",
                table: "PaymentDetails");

            migrationBuilder.DropColumn(
                name: "ConsentGivenAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "ConsentVersion",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "FailedLoginAttempts",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LastLoginAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LastLoginIp",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LockoutUntil",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "People");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "People");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "People");

            migrationBuilder.DropColumn(
                name: "Currency",
                table: "PaymentDetails");

            migrationBuilder.DropColumn(
                name: "TransactionId",
                table: "PaymentDetails");
        }
    }
}
