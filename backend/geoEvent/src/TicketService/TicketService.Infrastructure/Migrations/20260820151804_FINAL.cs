using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TicketService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FINAL : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Tickets",
                columns: table => new
                {
                    TicketId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EventId = table.Column<int>(type: "int", nullable: false),
                    TicketType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Price = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalQuantity = table.Column<int>(type: "int", nullable: false),
                    SoldQuantity = table.Column<int>(type: "int", nullable: false),
                    SaleStartDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SaleEndDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    PriceZoneId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Tickets", x => x.TicketId);
                    table.CheckConstraint("CK_Tickets_SoldQuantity", "[SoldQuantity] >= 0 AND ([TotalQuantity] = 0 OR [SoldQuantity] <= [TotalQuantity])");
                });

            migrationBuilder.CreateTable(
                name: "Reservations",
                columns: table => new
                {
                    ReservationId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReservedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EventId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    EventTicketId = table.Column<int>(type: "int", nullable: true),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    TotalAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ConfirmedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CancelledAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiredAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    PaymentReference = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    PendingProviderOrderId = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    PendingPaymentMethod = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    PendingPaymentCreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RefundRequestStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RefundReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    RefundRequestedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RefundReviewedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RefundReviewedByUserId = table.Column<int>(type: "int", nullable: true),
                    RefundDecisionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    RefundModeratorAction = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reservations", x => x.ReservationId);
                    table.ForeignKey(
                        name: "FK_Reservations_Tickets_EventTicketId",
                        column: x => x.EventTicketId,
                        principalTable: "Tickets",
                        principalColumn: "TicketId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "IssuedTickets",
                columns: table => new
                {
                    TicketId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReservationId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    EventId = table.Column<int>(type: "int", nullable: false),
                    TicketType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    QrCode = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IssuedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CancelledAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SeatNumber = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Section = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IssuedTickets", x => x.TicketId);
                    table.ForeignKey(
                        name: "FK_IssuedTickets_Reservations_ReservationId",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "ReservationId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PaymentDetails",
                columns: table => new
                {
                    PaymentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PaidAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReservationId = table.Column<int>(type: "int", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Method = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(3)", maxLength: 3, nullable: false, defaultValue: "BAM"),
                    ProviderPaymentId = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ProviderOrderId = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    TransactionId = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    RefundTransactionId = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentDetails", x => x.PaymentId);
                    table.ForeignKey(
                        name: "FK_PaymentDetails_Reservations_ReservationId",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "ReservationId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_EventId",
                table: "IssuedTickets",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_IssuedAt",
                table: "IssuedTickets",
                column: "IssuedAt");

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_QrCode",
                table: "IssuedTickets",
                column: "QrCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_ReservationId",
                table: "IssuedTickets",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_Status",
                table: "IssuedTickets",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_UserId",
                table: "IssuedTickets",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_PaidAt",
                table: "PaymentDetails",
                column: "PaidAt");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_ReservationId",
                table: "PaymentDetails",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_Status",
                table: "PaymentDetails",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_TransactionId",
                table: "PaymentDetails",
                column: "TransactionId",
                unique: true,
                filter: "[TransactionId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentDetails_UserId",
                table: "PaymentDetails",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_EventId",
                table: "Reservations",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_EventTicketId",
                table: "Reservations",
                column: "EventTicketId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ExpiresAt",
                table: "Reservations",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_PendingProviderOrderId",
                table: "Reservations",
                column: "PendingProviderOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_RefundRequestStatus",
                table: "Reservations",
                column: "RefundRequestStatus");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ReservedAt",
                table: "Reservations",
                column: "ReservedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_Status_ExpiresAt",
                table: "Reservations",
                columns: new[] { "Status", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_EventId",
                table: "Tickets",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_EventId_IsActive",
                table: "Tickets",
                columns: new[] { "EventId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_IsActive",
                table: "Tickets",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_SaleStartDate_SaleEndDate",
                table: "Tickets",
                columns: new[] { "SaleStartDate", "SaleEndDate" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IssuedTickets");

            migrationBuilder.DropTable(
                name: "PaymentDetails");

            migrationBuilder.DropTable(
                name: "Reservations");

            migrationBuilder.DropTable(
                name: "Tickets");
        }
    }
}
