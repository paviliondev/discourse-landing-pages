class LandingPages::Menu
  def self.items
    [
      {
        label: "Services",
        items: [
          {
            label: "Customisations",
            href: "/customisations",
            description: "We work on your community"
          },
          {
            label: "Support",
            href: "/support",
            description: "We support your community"
          },
          {
            label: "Education",
            href: "/education",
            description: "We help you learn about your community"
          },
          {
            label: "Pro Bono",
            href: "/pro-bono",
            description: "We work with non-profits and charities"
          },
          {
            label: "Showcase",
            href: "/showcase",
            description: "Showcase of some of our work"
          }
        ]
      },
      {
        label: "Open Source"
      },
      {
        label: "Members"
      }
    ]
  end
end