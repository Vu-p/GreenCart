namespace GreenCart.Api.Models;

public static class OrderStatuses
{
    public const string Pending = "Pending";
    public const string Confirmed = "Confirmed";
    public const string Packing = "Packing";
    public const string Delivering = "Delivering";
    public const string Completed = "Completed";
    public const string Cancelled = "Cancelled";

    public static readonly string[] All =
    [
        Pending,
        Confirmed,
        Packing,
        Delivering,
        Completed,
        Cancelled
    ];
}
