using Microsoft.EntityFrameworkCore;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Persistence;

public class TicketDbContext : DbContext
{
    public TicketDbContext(DbContextOptions<TicketDbContext> options) : base(options) { }

    public DbSet<EventTicket> EventTickets => Set<EventTicket>();
    public DbSet<Reservation> Reservations => Set<Reservation>();
    public DbSet<PaymentDetail> PaymentDetails => Set<PaymentDetail>();
    public DbSet<Ticket> IssuedTickets => Set<Ticket>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(TicketDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}