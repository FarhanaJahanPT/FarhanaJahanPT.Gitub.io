from odoo import models, exceptions,_


class IrAttachment(models.Model):
    _inherit = 'ir.attachment'

    def unlink(self):
        if not self.env.user.has_group('beyond_worksheet.group_beyond_worksheet_admin'):
            for attachment in self:
                if attachment.res_model in ['task.worksheet','worksheet.attendance','electrical.contract.license','mail.message']:
                    raise exceptions.AccessError(_(
                        "You do not have sufficient rights to delete this attachment."
                    ))
        return super(IrAttachment, self).unlink()