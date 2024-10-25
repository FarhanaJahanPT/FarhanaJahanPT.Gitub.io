from odoo import fields, models


class TeamMember(models.Model):
    _name = 'team.member'
    _description = 'Team member'

    member_id = fields.Char("Member ID", required=True, copy=False)
    name = fields.Char('Name', required=True)
    mobile = fields.Char('Mobile')
    country_id = fields.Many2one('res.country', string='Country')

    _sql_constraints = [
        ('uniq_member_id', 'UNIQUE(member_id)', 'This Member ID is already Exist'),
    ]
