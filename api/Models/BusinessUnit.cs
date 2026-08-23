namespace api.Models;

public class BusinessUnit
{
    public string BUID { get; set; } = null!;
    public string? Description { get; set; }
    public string? DescriptionA { get; set; }
    public string? ParentBU { get; set; }
    public byte Level { get; set; }
    public string? ShortCode { get; set; }
}
