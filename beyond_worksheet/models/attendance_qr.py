# -*- coding: utf-8 -*-
try:
    import qrcode
except ImportError:
    qrcode = None
try:
    import base64
except ImportError:
    base64 = None
from io import BytesIO
from odoo import api, models, fields


class AttendanceQR(models.Model):
    _name = 'attendance.qr'
    _description = 'Attendance QR'

    user_id = fields.Many2one('res.users', string='Team Member', required=True)
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet')
    qr_code = fields.Binary("QR Code", compute='_compute_qr_code', store=True)

    @api.model_create_multi
    def create(self, vals_list):
        res = super(AttendanceQR, self).create(vals_list)
        self.env['worksheet.history'].sudo().create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': self.env.user.id,
            'changes': 'Generate QR',
            'details': 'Attendance QR code has been successfully generated for the user ({}).'.format(res.user_id.name),
        })
        return res

    @api.depends('user_id')
    def _compute_qr_code(self):
        for rec in self:
            if qrcode and base64:
                qr = qrcode.QRCode(
                    version=1,
                    error_correction=qrcode.constants.ERROR_CORRECT_L,
                    box_size=3,
                    border=4,
                )
                qr.add_data(
                    f'http://10.0.10.41:8017/my/worksheet/{self.user_id.id}/{self.worksheet_id.id}')
                qr.make(fit=True)
                img = qr.make_image()
                temp = BytesIO()
                img.save(temp, format="PNG")
                qr_image = base64.b64encode(temp.getvalue())
                rec.qr_code = qr_image
