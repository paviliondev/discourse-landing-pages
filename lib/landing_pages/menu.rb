class LandingPages::Menu
  def self.items
    [
      {
        label: "Services",
        description: "We provide software development, design, product development, technical support and site administration for online communities.",
        items: [
          {
            label: "Customisations",
            href: "/customisations",
            description: "We customise community software to fit your use case"
          },
          {
            label: "Support",
            href: "/support",
            description: "We provide technical support to community managers"
          },
          {
            label: "Showcase",
            href: "/showcase",
            description: "Case studies and observations from our work"
          },
          {
            label: "Education",
            href: "/education",
            description: "Courses on practical technical skills for community managers",
            coming_soon: true
          }
        ]
      },
      {
        label: "Open Source",
        description: "We maintain open source plugins, themes, scripts and example implementions for these community platforms.",
        items: [
          {
            label: "Discourse",
            href: "/discourse",
            description: "Market-leading forum software"
          },
          {
            label: "Wordpress",
            href: "/wordpress",
            description: "Widely-used website and blog builder",
            coming_soon: true
          },
          {
            label: "Auth0",
            href: "/auth0",
            description: "Market-leading identity management platform",
            coming_soon: true
          },
          {
            label: "Shopify",
            href: "/shopify",
            description: "Market-leading shop platform",
            coming_soon: true
          },
          {
            label: "Discord",
            href: "/discord",
            description: "Community-focused chat application",
            coming_soon: true
          },
          {
            label: "Minecraft",
            href: "/minecraft",
            description: "Popular customisable game environment",
            coming_soon: true
          }
        ]
      },
      {
        label: "Coöperative",
        description: "Pavilion exists to provide livelihoods for our workers, support online communities and empower open source.",
        items:[
          {
            label: "Coöperative",
            href: "/coöperative",
            description: "More about our coöperative and its goals"
          },
          {
            label: "Workers",
            href: "/workers",
            description: "More about our worker members"
          },
          {
            label: "Community",
            href: "/community",
            description: "More about our community members",
            coming_soon: true
          },
          {
            label: "Join",
            href: "/join",
            description: "How you can join Pavilion",
            coming_soon: true
          },
        ]
      }
    ]
  end
end