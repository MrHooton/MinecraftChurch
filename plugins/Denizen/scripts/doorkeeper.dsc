doorkeeper_assign:
  type: assignment
  actions:
    on assignment:
    - trigger name:click state:true

    on click:
    - narrate "<&7>Welcome. Some rooms open when a grown-up helps.<&r>"
    - narrate "<&7>You can explore here while they do.<&r>"
    - narrate "<&7>If you want, show them the sign near the door.<&r>"
