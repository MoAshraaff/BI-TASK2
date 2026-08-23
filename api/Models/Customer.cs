namespace api.Models;

public class Customer
{
    public string CustomerNo { get; set; } = null!;
    public string? CustomerNameE { get; set; }
    public string? CustomerNameA { get; set; }
    public string? SalesmanNo { get; set; }
    public string? BUID { get; set; }
    public string? Mobile { get; set; }
    public string? Address { get; set; }
    public byte? InActive { get; set; }
}
