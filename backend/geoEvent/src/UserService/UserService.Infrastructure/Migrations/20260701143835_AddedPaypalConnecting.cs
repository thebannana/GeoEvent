using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UserService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddedPaypalConnecting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "HasPayPalConnected",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "PayPalConnectedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayPalConnectionStatus",
                table: "Users",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayPalEmail",
                table: "Users",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayPalMerchantId",
                table: "Users",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayPalTrackingId",
                table: "Users",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_PayPalMerchantId",
                table: "Users",
                column: "PayPalMerchantId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_PayPalTrackingId",
                table: "Users",
                column: "PayPalTrackingId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_PayPalMerchantId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_PayPalTrackingId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "HasPayPalConnected",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PayPalConnectedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PayPalConnectionStatus",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PayPalEmail",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PayPalMerchantId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PayPalTrackingId",
                table: "Users");
        }
    }
}
