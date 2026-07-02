namespace GreenCart.Api.Options;

public sealed class PayOsOptions
{
    public const string SectionName = "PayOS";

    public string? ClientId { get; set; }
    public string? ApiKey { get; set; }
    public string? ChecksumKey { get; set; }
    public string? PartnerCode { get; set; }
    public string? ReturnUrl { get; set; }
    public string? CancelUrl { get; set; }
    public string AppSuccessUrl { get; set; } = "greencart:///checkout/success";
    public string AppCancelUrl { get; set; } = "greencart:///orders";
    public decimal AmountMultiplier { get; set; } = 1m;
}
