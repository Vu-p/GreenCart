namespace GreenCart.Api.Models;

public sealed class RealtimeEvent
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public Guid? OrderId { get; set; }
    public required string Type { get; set; }
    public required string Payload { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
