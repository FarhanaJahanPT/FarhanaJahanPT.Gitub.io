# -*- coding: utf-8 -*-
import re
import fitz
import io
from datetime import datetime, timedelta
try:
    import qrcode
except ImportError:
    qrcode = None
try:
    import base64
except ImportError:
    base64 = None
from odoo import api, fields, models, _
from odoo.modules.module import get_module_resource


class WorkSheet(models.Model):
    _name = 'task.worksheet'
    _description = "Worksheet"
    _inherit = ['mail.thread', 'mail.activity.mixin']

    partner_id = fields.Many2one(string='Customer', related='task_id.partner_id')
    name = fields.Char("Name", default=lambda self: _('New'))
    task_id = fields.Many2one('project.task', string='Task')
    sale_id = fields.Many2one('sale.order', string='Sale Order', related="task_id.sale_order_id")
    panel_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                    string='Panel Serial Number', domain=[('type', '=', 'panel')], readonly=True)
    inverter_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                       string='Inverter Serial Number', domain=[('type', '=', 'inverter')],
                                       readonly=True)
    battery_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                      string='Battery Serial Number', domain=[('type', '=', 'battery')], readonly=True)
    team_member_ids = fields.Many2many('team.member', string='Members')
    qr_code = fields.Binary("QR Code", copy=False)
    member_question_ids = fields.One2many('worksheet.member.question', 'worksheet_id')
    panel_count = fields.Integer(string='Panel Count', compute='_compute_order_count', store=True, default=0)
    inverter_count = fields.Integer(string='Inverter Count', compute='_compute_order_count', store=True, default=0)
    battery_count = fields.Integer(string='Battery Count', compute='_compute_order_count', store=True, default=0)
    checklist_item_ids = fields.One2many('installation.checklist.item', 'worksheet_id',
                                         domain=[('checklist_id.selfie_type', '=', 'null')])
    service_item_ids = fields.One2many('service.checklist.item', 'worksheet_id',
                                       domain=[('service_id.selfie_type', '=', 'null')])
    is_checklist = fields.Boolean(string='Checklist', compute='_compute_is_checklist', store=True)
    checklist_count = fields.Integer(string='Checklist Count', compute='_compute_is_checklist', store=True)
    witness_signature = fields.Char(string="Witness Signature", copy=False)
    witness_signature_date = fields.Datetime(string="Witness Signature Date", copy=False)
    x_studio_type_of_service = fields.Selection(string='Type of Service',
                                                related='sale_id.x_studio_type_of_service', readonly=True)
    worksheet_attendance_ids = fields.One2many('worksheet.attendance', 'worksheet_id', string='Worksheet Attendance')
    invoice_count = fields.Integer(string="Invoice Count", compute='_compute_invoice_count', help='Total invoice count')
    is_ces_activity_created = fields.Boolean(string="CES Activity created")
    is_ccew = fields.Boolean(string='Is CCEW', compute='_compute_is_ccew')
    ccew_sequence = fields.Char(string='Sequence')
    ccew_file = fields.Binary(string='CCEW', related='task_id.x_studio_ccew', store=True)
    worksheet_history_ids = fields.One2many('worksheet.history','worksheet_id', readonly=True)
    site_address = fields.Char(string='Site Address', related='task_id.x_studio_site_address_1')
    scheduled_date = fields.Datetime(string='Scheduled Date of Service', related='task_id.planned_date_start')
    date_deadline = fields.Datetime(related='task_id.date_deadline')
    proposed_team_id = fields.Many2one('res.users',string='Assigned Installer', related='task_id.x_studio_proposed_team')
    team_lead_id = fields.Many2one('team.member', string='Assigned Installer', related='task_id.team_lead_id')
    solar_panel_layout = fields.Binary('Solar Panel Layout', related='sale_id.x_studio_solar_panel_layout')
    licence_expiry_date = fields.Date(string='Electrical Licence Expiry', compute="_compute_license_expiry_date")
    installation_type = fields.Selection([('first_time','First Time Installation'),('additional_system','Additional System'),('replacement','Replacement')],compute="_compute_installation_type")
    work_type_ids = fields.Many2many('work.type', string='Work Type', compute='compute_work_type_ids', store=True)
    spv_state = fields.Selection([('valid', 'Valid'),('invalid', 'Invalid'), ('null', ' ')],
                                 string='SPV', compute='compute_spv_state', store=True)
    document_ids = fields.One2many('documents.document', 'res_id',
                                   string='Documents', domain=[('res_model', '=', 'task.worksheet')])
    document_count = fields.Integer(string="Documents Count", compute='_compute_document_count')
    team_member_input_ids = fields.One2many('swms.team.member.input','worksheet_id')
    cranes_ids = fields.Many2many('swms.risk.work','task_worksheet_cranes_rel',
                                  'worksheet_id','work_id',
                                  string="Cranes",domain=[('type', '=', 'cranes')])
    hoists_ids = fields.Many2many('swms.risk.work','task_worksheet_hoists_rel',
                                  'worksheet_id','work_id',
                                  string="Hoists",domain=[('type', '=', 'hoists')])
    scaffolding_ids = fields.Many2many('swms.risk.work','task_worksheet_scaffolding_rel',
                                       'worksheet_id','work_id',
                                       string="Scaffolding",domain=[('type', '=', 'scaffolding')])
    dogging_rigging_ids = fields.Many2many('swms.risk.work','task_worksheet_dogging_rigging_rel',
                                           'worksheet_id','work_id',
                                           string="Dogging and Rigging",domain=[('type', '=', 'dogging_rigging')])
    forklift_ids = fields.Many2many('swms.risk.work','task_worksheet_forklift_rel',
                                    'worksheet_id','work_id',
                                    string="Forklift",domain=[('type', '=', 'forklift')])
    swms_file = fields.Binary(string='SWMS')

    @api.model_create_multi
    def create(self, vals_list):
        """Function to create sequence"""
        for vals in vals_list:
            if not vals.get('name') or vals['name'] == _('New'):
                vals['name'] = self.env['ir.sequence'].next_by_code('task.worksheet') or _('New')
        res = super(WorkSheet, self).create(vals_list)
        self.env['worksheet.history'].sudo().create({
            'worksheet_id': res.id,
            'user_id': self.env.user.id,
            'changes': 'Create',
            'details': ' Worksheet ({}) has been create successfully.'.format(res.name),
        })
        if res.team_lead_id:
            self.env['worksheet.history'].sudo().create({
                'worksheet_id': res.id,
                'user_id': res.env.user.id,
                'changes': 'Assigned Team Leader',
                'details': 'Worksheet assigned to ({}) has been successfully updated.'.format(res.team_lead_id.name),
            })
            model_id = self.env['ir.model'].search(
                [('model', '=', 'task.worksheet')], limit=1).id
            self.env['worksheet.notification'].sudo().create([{
                'author_id': res.env.user.id,
                'team_id': res.team_lead_id.id,
                'model_id': model_id,
                'res_id': res.id,
                'date': datetime.now(),
                'subject': 'Worksheet Assigned',
                'body': '{} has been assigned to you for installation on the {}'.format(res.name, res.scheduled_date),
            }])
        return res

    def _compute_license_expiry_date(self):
        for rec in self:
            nsw_ref = rec.env.ref('base.state_au_2').code
            act_ref = rec.env.ref('base.state_au_1').code
            state_code = rec.partner_id.state_id.code
            contract_licenses = rec.team_lead_id.contract_license_ids
            if state_code == nsw_ref:
                license = contract_licenses.filtered(lambda l: l.type == 'nsw')
            elif state_code == act_ref:
                license = contract_licenses.filtered(lambda l: l.type == 'act')
            else:
                license = False
            rec.licence_expiry_date = license.expiry_date if license else False

    def _compute_installation_type(self):
        for rec in self:
            if rec.task_id.x_studio_has_existing_system_installed == 'Yes' and rec.x_studio_type_of_service == 'New Installation':
                rec.installation_type = 'additional_system'
            elif rec.task_id.x_studio_has_existing_system_installed == 'No' and rec.x_studio_type_of_service == 'New Installation':
                rec.installation_type = 'first_time'
            elif rec.x_studio_type_of_service == 'Replacement':
                rec.installation_type = 'replacement'
            else:
                rec.installation_type = False

    def write(self, vals):
        res = super().write(vals)
        if (self.battery_count or self.inverter_count) and not self.is_ces_activity_created:
            operation_team = self.env['hr.employee'].search(
                [('department_id', '=', self.env.ref('beyond_worksheet.dep_operations').id)]).user_id
            for member in operation_team:
                self.sudo().activity_schedule(
                    activity_type_id=self.env.ref('mail.mail_activity_data_todo').id,
                    date_deadline=fields.Datetime.now(),
                    note=_('Need To Generate CES'),
                    user_id=member.id)
            # self.is_ces_activity_created = True if operation_team else False
        if self.ccew_file and not self.ccew_sequence:
            seq = self.env['ir.sequence'].next_by_code('ccew.sequence')
            license_id = self.team_lead_id.contract_license_ids.filtered(lambda l: l.type == 'nsw')
            license = '-' + (str(license_id.number) + '/' if license_id else '' ) + str(
                self.team_lead_id.name) + '-'
            self.ccew_sequence = seq.replace('--', license)
            self.env['worksheet.history'].sudo().create({
                'worksheet_id': self.id,
                'user_id': self.env.user.id,
                'changes': 'Update',
                'details': ' CCEW sequence ({}) has been updated successfully.'.format(self.ccew_sequence),
            })
        for val in vals:
            key = val
            values = vals.get(val)
            if isinstance(values,bool) and key != 'ccew_file':
                self.env['worksheet.history'].sudo().create({
                    'worksheet_id': self.id,
                    'user_id': self.env.user.id,
                    'changes': 'Update',
                    'details': ' {} has been enabled successfully.'.format(key) if values == True else ' {} has been disabled successfully.'.format(key),
                })
            elif key == 'team_member_ids':
                for value in values:
                    user = self.team_member_ids.browse(value[1])
                    if value[0] == 4:
                        self.env['worksheet.history'].sudo().create({
                            'worksheet_id': self.id,
                            'user_id': self.env.user.id,
                            'changes': 'Assigned Team Member',
                            'details': '({}) has been successfully added.'.format(user.name),
                        })
                    elif value[0] == 3:
                        self.env['worksheet.history'].sudo().create({
                            'worksheet_id': self.id,
                            'user_id': self.env.user.id,
                            'changes': 'Removed Team Member',
                            'details': '({}) has been successfully removed.'.format(user.name),
                        })
        return res

    @api.depends('sale_id')
    def compute_work_type_ids(self):
        for rec in self:
            rec.work_type_ids = None
            if rec.sale_id._get_stc_values('total') != 0:
                rec.work_type_ids =[(4, self.env.ref('beyond_worksheet.work_type_1').id)]
            if rec.sale_id._get_prc_values('total') != 0:
                rec.work_type_ids = [(4, self.env.ref('beyond_worksheet.work_type_2').id)]

    @api.depends('panel_lot_ids.state')
    def compute_spv_state(self):
        for rec in self:
            if rec.panel_lot_ids:
                any_invalid = any(panel.state == 'invalid' for panel in rec.panel_lot_ids)
                all_verified = all(panel.state == 'verified' for panel in rec.panel_lot_ids)
                if any_invalid:
                    rec.spv_state = 'invalid'
                elif all_verified:
                    rec.spv_state = 'valid'
                else:
                    rec.spv_state = 'null'
            else:
                rec.spv_state = 'null'

    @api.depends('sale_id')
    def _compute_order_count(self):
        for rec in self:
            order_line = rec.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Inverters' or sol.product_id.categ_id.parent_id.name == 'Inverters')[:1]
            rec.inverter_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_id.order_line.filtered(
                lambda sol: sol.product_id.categ_id.name == 'Solar Panels')[:1]
            rec.panel_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Storage')[:1]
            rec.battery_count = sum(order_line.mapped('product_uom_qty'))

    @api.depends('partner_id')
    def _compute_is_ccew(self):
        for rec in self:
            if rec.partner_id.state_id == self.env.ref('base.state_au_2'):
                rec.is_ccew = True
            else:
                rec.is_ccew = False

    @api.depends('checklist_item_ids', 'service_item_ids')
    def _compute_is_checklist(self):
        for rec in self:
            rec.is_checklist = False
            rec.checklist_count = 0
            order_line = rec.sale_id.order_line.product_id.categ_id.mapped('id')
            if rec.x_studio_type_of_service == 'New Installation':
                checklist_ids = self.env['installation.checklist'].search([('category_ids', 'in', order_line)]).mapped('min_qty')
                rec.checklist_count = sum(checklist_ids)
                if sum(checklist_ids) == len(rec.checklist_item_ids):
                    rec.is_checklist = True
            if rec.x_studio_type_of_service == 'Service':
                checklist_ids = self.env['service.checklist'].search([('category_ids', 'in', order_line)]).mapped('min_qty')
                rec.checklist_count = sum(checklist_ids)
                if sum(checklist_ids) == len(rec.service_item_ids):
                    rec.is_checklist = True

    def action_generate_qr_code(self):
        if qrcode and base64:
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=3,
                border=4,
            )
            url = self.env['ir.config_parameter'].sudo().get_param('web.base.url')
            qr.add_data(f'{url}/my/worksheet/{self.id}')
            qr.make(fit=True)
            img = qr.make_image()
            temp = io.BytesIO()
            img.save(temp, format="PNG")
            qr_image = base64.b64encode(temp.getvalue())
            self.qr_code = qr_image

    def _compute_invoice_count(self):
        """Function to count invoice"""
        for record in self:
            record.invoice_count = self.env['account.move'].search_count([('invoice_origin', '=', self.name)])

    def _compute_document_count(self):
        for record in self:
            record.document_count = self.env['documents.document'].search_count(
                [('res_model', '=', 'task.worksheet'), ('res_id', '=', record.id)])

    def get_sale_order(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Sale Order',
            'view_mode': 'form',
            'res_model': 'sale.order',
            'res_id': self.sale_id.id,
            'context': "{'create': False}"
        }

    def get_task(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Task',
            'view_mode': 'form',
            'res_model': 'project.task',
            'res_id': self.task_id.id,
            'context': "{'create': False}"
        }

    def _generate_attendance_invoice_cron(self):
        today = datetime.today()
        monday = today - timedelta(days=today.weekday())
        friday = monday + timedelta(days=4)
        attendance_ids = self.env['worksheet.attendance'].search([('datetime', '>=', monday.date()),('datetime', '<=', friday.date())])
        for worksheet_id in attendance_ids.worksheet_id:
            if worksheet_id:
                for user_id in worksheet_id.worksheet_attendance_ids.user_id:
                    service = worksheet_id.worksheet_attendance_ids.filtered(lambda w: w.type == 'check_in' and w.user_id == user_id)
                    additional = worksheet_id.worksheet_attendance_ids.filtered(lambda w: w.additional_service == True and w.user_id == user_id)
                    vals = []
                    if service:
                        vals.append((0, 0,{'name': "Services at {}".format(worksheet_id.name),
                                         'quantity': 1,
                                         'price_unit': service[:1].user_id.invoice_amount}))
                    if additional:
                        vals.append((0, 0,{'name': "Additional service item at {}".format(worksheet_id.name),
                                         'quantity': 1,
                                         'price_unit': additional[:1].user_id.invoice_amount}))
                    invoice = self.env['account.move'].sudo().create([{
                        'name': self.env['ir.sequence'].next_by_code('rcti.invoice'),
                        'move_type': 'in_invoice',
                        'partner_id': user_id.partner_id.id,
                        'invoice_origin': worksheet_id.name,
                        'date': worksheet_id.task_id.planned_date_begin,
                        'invoice_date_due': today.date() + timedelta(days=5),
                        'invoice_line_ids': vals
                    }])

    def get_invoice(self):
        """Smart button to view the Corresponding Invoices for the Worksheet"""
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Invoice',
            'view_mode': 'tree,form',
            'res_model': 'account.move',
            'target': 'current',
            'domain': [('invoice_origin', '=', self.name)],
            'context': {"create": False},
        }

    def get_documents(self):
        self.ensure_one()
        return {
            'res_model': 'documents.document',
            'type': 'ir.actions.act_window',
            'name': _("%(worksheet_name)s's Documents", worksheet_name=self.name),
            'domain': [('res_model', '=', 'task.worksheet'), ('res_id', '=', self.id),],
            'view_mode': 'kanban,tree,form',
            'context': {'default_res_model': 'task.worksheet', 'default_res_id': self.id,},
        }

    @api.model
    def get_checklist_values(self, vals):
        data = []
        checklist = []
        order_line = self.browse(vals).sale_id.order_line.product_id.categ_id.mapped('id')
        if self.browse(vals).x_studio_type_of_service == 'New Installation':
            checklist_ids = self.env['installation.checklist'].search([('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['installation.checklist.item'].search([('worksheet_id', '=', vals)])
            for checklist_id in checklist_ids:
                data.append([checklist_id.id, checklist_id.name, checklist_id.type])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.checklist_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        elif self.browse(vals).x_studio_type_of_service == 'Service':
            checklist_ids = self.env['service.checklist'].search([('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['service.checklist.item'].search([('worksheet_id', '=', vals)])
            for checklist_id in checklist_ids:
                data.append(
                    [checklist_id.id, checklist_id.name, checklist_id.type])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.service_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        return data, checklist

    @api.model
    def get_overview_values(self,vals):
        data = []
        checklist = []
        serial_number = []
        serial_count = []
        record = self.browse(vals)
        serial_count.append([record.panel_count,len(record.panel_lot_ids), 'panel'])
        serial_count.append([record.inverter_count,len(record.inverter_lot_ids), 'inverter'])
        serial_count.append([record.battery_count,len(record.battery_lot_ids), 'battery'])
        order_line =record.sale_id.order_line.product_id.categ_id.mapped('id')
        if record.x_studio_type_of_service == 'New Installation':
            checklist_ids = self.env['installation.checklist'].search(
                [('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['installation.checklist.item'].search([('worksheet_id', '=', vals)])
            for checklist_id in checklist_ids:
                total = 0
                for checklist_item_id in checklist_item_ids:
                    if checklist_item_id.checklist_id.id == checklist_id.id:
                        total += 1
                compliant = checklist_item_ids.filtered(lambda c: c.checklist_id == checklist_id)[:1].compliant
                data.append(
                    [checklist_id.id, checklist_id.icon, checklist_id.name,
                     checklist_id.group, checklist_id.min_qty, total,
                     checklist_id.type, checklist_id.compliant_note,
                     compliant, 'installation'])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.checklist_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        elif record.x_studio_type_of_service == 'Service':
            checklist_ids = self.env['service.checklist'].search(
                [('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['service.checklist.item'].search(
                [('worksheet_id', '=', vals)])
            for checklist_id in checklist_ids:
                total = 0
                for checklist_item_id in checklist_item_ids:
                    if checklist_item_id.service_id.id == checklist_id.id:
                        total += 1
                compliant = checklist_item_ids.filtered(lambda c: c.service_id == checklist_id)[:1].compliant
                data.append(
                    [checklist_id.id, checklist_id.icon, checklist_id.name,
                     checklist_id.group, checklist_id.min_qty, total,
                     checklist_id.type, checklist_id.compliant_note,
                     compliant, 'service'])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.service_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        return data, serial_count, checklist

    @api.model
    def get_checklist_compliant(self,vals,ev):
        if self.browse(vals).x_studio_type_of_service == 'New Installation':
            checklist_item_ids = self.env['installation.checklist.item'].search([('worksheet_id', '=', vals),('checklist_id','=',ev[0])])
        else:
            checklist_item_ids = self.env['service.checklist.item'].search([('worksheet_id', '=', vals), ('service_id', '=', ev[0])])
        for checklist_item_id in checklist_item_ids:
            checklist_item_id.compliant = not checklist_item_id.compliant

    @api.constrains('panel_lot_ids', 'inverter_lot_ids', 'battery_lot_ids')
    def get_delivered_items(self):
        for rec in self:
            move_ids = rec.sale_id.picking_ids.move_ids_without_package
            move_line_ids = rec.sale_id.picking_ids.move_line_ids
            lot_ids = self.env['stock.lot'].search([('worksheet_id', '=',rec.id)])
            for lot_id in lot_ids:
                if move_line_ids.lot_id not in lot_id:
                    move_line_id = {'product_id':lot_id.product_id.id,
                                    'lot_id': lot_id.id,
                                    'quantity': 1,
                                    'picking_id': rec.sale_id.picking_ids.id,
                                    'move_id': move_ids.filtered(lambda w: w.product_id == lot_id.product_id)[:1].id,
                                    'reference': rec.sale_id.picking_ids.name,
                                    'location_id': rec.sale_id.picking_ids.location_id.id,
                                    'location_dest_id': rec.sale_id.picking_ids.location_dest_id.id,
                                    'state': 'assigned',
                                    }
                    move = move_line_ids.sudo().create(move_line_id)

    def action_create_ccew(self):
        partner_shipping_id = self.sale_id.partner_shipping_id
        if partner_shipping_id.state_id.code == 'NSW':
            address = partner_shipping_id.street
            name = self.partner_id.name
            unit_value_1 = ''
            remaining_address_1 = ''
            number_1 = ''
            if address:
                words = address.split()
                if "Unit" in words:
                    unit_index = words.index("Unit")
                    if unit_index + 1 < len(words):
                        unit_value_1 = f"Unit {words[unit_index + 1]}"
                        remaining_address_1 = ' '.join(words[unit_index + 2:])
                elif any(char.isdigit() for char in address):
                    match = re.search(r'\d+', address)
                    if match:
                        number_1 = match.group()
                        remaining_address_1 = address.replace(number_1, "", 1).strip()
                else:
                    remaining_address_1 = ' '.join(words)
            if name:
                words = [word.strip() for word in re.split(r'[\s\|]+', name) if word.strip()]
                if len(words) > 1:
                    first_name = words[0]
                    last_name = words[-1]
                else:
                    first_name = words[0]
                    last_name = ''
            image_path = get_module_resource('beyond_worksheet','static/src/img/tick.png')
            pdf_path = get_module_resource('beyond_worksheet','static/src/data/CCEW.pdf')
            doc = fitz.open(pdf_path)
            page = doc[0]
            # Insert the any text
            page.insert_text((440, 72), self.name, fontsize=10, color=(0, 0, 0))
            page.insert_text((47, 180), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((47, 216), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((117, 216), unit_value_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((304, 216), number_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((436, 216), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((47,251), remaining_address_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((303,251), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((47,286), partner_shipping_id.city, fontsize=10, color=(0, 0, 0))
            if partner_shipping_id.state_id:
                page.insert_text((303,286), partner_shipping_id.state_id.code, fontsize=10, color=(0, 0, 0))
            page.insert_text((475,286), partner_shipping_id.zip, fontsize=10, color=(0, 0, 0))
            page.insert_text((47,323), '', fontsize=10, color=(0, 0, 0))
            if self.task_id.x_studio_nmi:
                page.insert_text((175,323), self.task_id.x_studio_nmi, fontsize=10, color=(0, 0, 0))
            page.insert_text((276,323), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((392, 323), '', fontsize=10, color=(0, 0, 0))
            if self.partner_id.id == partner_shipping_id.id:
                rect = fitz.Rect(198, 343, 219, 359)
                page.insert_image(rect, filename=image_path)
            else:
                address = self.partner_id.street
                unit_value_1 = ''
                remaining_address_1 = ''
                number_1 = ''
                if address:
                    words = address.split()
                    if "Unit" in words:
                        unit_index = words.index("Unit")
                        if unit_index + 1 < len(words):
                            unit_value_1 = f"Unit {words[unit_index + 1]}"
                            remaining_address_1 = ' '.join(words[unit_index + 2:])
                    elif any(char.isdigit() for char in address):
                        match = re.search(r'\d+', address)
                        if match:
                            number_1 = match.group()
                            remaining_address_1 = address.replace(number_1, "",1).strip()
                    else:
                        remaining_address_1 = ' '.join(words)
            page.insert_text((47, 390), first_name, fontsize=10, color=(0, 0, 0))
            page.insert_text((301,390), last_name, fontsize=10, color=(0, 0, 0))
            if self.partner_id.is_company:
                page.insert_text((47,425), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((178,460), unit_value_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((301,460), number_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((47,495), remaining_address_1, fontsize=10, color=(0, 0, 0))
            page.insert_text((301,495), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((47,530), self.partner_id.city, fontsize=10, color=(0, 0, 0))
            if self.partner_id.state_id:
                page.insert_text((301,530), self.partner_id.state_id.code, fontsize=10, color=(0, 0, 0))
            page.insert_text((471,530), self.partner_id.zip, fontsize=10, color=(0, 0, 0))
            page.insert_text((47,565), self.partner_id.email, fontsize=10, color=(0, 0, 0))
            page.insert_text((375,565), '', fontsize=10, color=(0, 0, 0))
            page.insert_text((471,565), self.partner_id.mobile if self.partner_id.mobile else self.partner_id.phone, fontsize=10, color=(0, 0, 0))
            premises_types = {
                'Residential': (110, 620, 130, 637),
                'Commerical': (218, 620, 239, 637),
                'Industrial': (311, 620, 333, 637)
            }
            premises_value = self.task_id.x_studio_3_type_of_premises
            if premises_value in premises_types:
                page.insert_image(premises_types[premises_value], filename=image_path)
            page.insert_image((199,658,219,674), filename=image_path)
            inverter = self.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Inverters' or sol.product_id.categ_id.parent_id.name == 'Inverters' and sol.product_id.is_testing_required == True)[:1]
            panel = self.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Solar Panels' and sol.product_id.is_testing_required == True)[:1]
            battery = self.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Storage' and sol.product_id.is_testing_required == True)[:1]
            page = doc[1]
            if panel:
                page.insert_image((43, 109, 63, 127.53), filename=image_path)
                page.insert_text((249, 124), str(panel.product_uom_qty),fontsize=10, color=(0, 0, 0))
                page.insert_text((366, 124), panel.product_id.name, fontsize=8,color=(0, 0, 0))
            if inverter:
                page.insert_text((249, 144), str(inverter.product_uom_qty),fontsize=10, color=(0, 0, 0))
                page.insert_text((366, 144), inverter.product_id.name,fontsize=8, color=(0, 0, 0))
            if battery:
                page.insert_text((249, 163), str(battery.product_uom_qty),fontsize=10, color=(0, 0, 0))
                page.insert_text((366, 163), battery.product_id.name,fontsize=8, color=(0, 0, 0))
            page.insert_image((412,486,431,503), filename=image_path)
            page.insert_image((412,508,431,523), filename=image_path)
            if self.team_lead_id.employee_id:
                partner_id = self.team_lead_id.employee_id.address_id
                address = partner_id.street
                name = self.team_lead_id.name
                if address:
                    words = address.split()
                    if "Unit" in words:
                        unit_index = words.index("Unit")
                        if unit_index + 1 < len(words):
                            unit_value_1 = f"Unit {words[unit_index + 1]}"
                            remaining_address_1 = ' '.join(words[unit_index + 2:])
                    elif any(char.isdigit() for char in address):
                        match = re.search(r'\d+', address)
                        if match:
                            number_1 = match.group()
                            remaining_address_1 = address.replace(number_1, "",1).strip()
                    else:
                        remaining_address_1 = ' '.join(words)
                if name:
                    words = [word.strip() for word in re.split(r'[\s\|]+', name) if
                             word.strip()]
                    if len(words) > 1:
                        first_name = words[0]
                        last_name = words[-1]
                    else:
                        first_name = words[0]
                        last_name = ''
                page.insert_text((47,580), first_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((300,580), last_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((177,610), unit_value_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((300,610), number_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((47,639), remaining_address_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((47,668), partner_id.city, fontsize=10,color=(0, 0, 0))
                page.insert_text((300,668), partner_id.state_id.code, fontsize=10,color=(0, 0, 0))
                page.insert_text((470,668), partner_id.zip, fontsize=10,color=(0, 0, 0))
                page.insert_text((47,697), self.team_lead_id.email, fontsize=10,color=(0, 0, 0))
                page.insert_text((470,697), self.team_lead_id.mobile, fontsize=10,color=(0, 0, 0))
                license_id = self.team_lead_id.contract_license_ids.filtered(lambda l: l.type == 'nsw')
                if license_id:
                    page.insert_text((309,727), license_id.number, fontsize=10,color=(0, 0, 0))
                    page.insert_text((451,727), str(license_id.expiry_date), fontsize=10,color=(0, 0, 0))
            page = doc[2]
            page.insert_image((64,88,81,101), filename=image_path)
            # page.insert_image((64,105,81,118), filename=image_path)
            page.insert_image((64,122,81,136), filename=image_path)
            page.insert_image((64,139,81,153), filename=image_path)
            page.insert_image((64,156,81,169), filename=image_path)
            # page.insert_image((63,173,81,186), filename=image_path)
            page.insert_image((64,189,81,203), filename=image_path)
            # page.insert_image((63,207,81,220), filename=image_path)
            if self.task_id.date_deadline:
                date_deadline = fields.Date.to_date(self.task_id.date_deadline)
                page.insert_text((219,262), str(date_deadline), fontsize=10,color=(0, 0, 0))
            if  self.team_lead_id:
                page.insert_image((237,281,252,292), filename=image_path)
                page.insert_text((47, 322), first_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 322), last_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((176, 351), unit_value_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 351), number_1, fontsize=10, color=(0, 0, 0))
                page.insert_text((47, 380), remaining_address_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((47, 410), partner_id.city, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 410), partner_id.state_id.code, fontsize=10,color=(0, 0, 0))
                page.insert_text((469, 410), partner_id.zip, fontsize=10,color=(0, 0, 0))
                page.insert_text((47, 438), self.team_lead_id.email, fontsize=10,color=(0, 0, 0))
                page.insert_text((469, 438),self.team_lead_id.mobile,fontsize=10, color=(0, 0, 0))
                if license_id:
                    page.insert_text((309, 468),license_id.number,fontsize=10, color=(0, 0, 0))
                    page.insert_text((452, 467),str(license_id.expiry_date),fontsize=10, color=(0, 0, 0))
            pdf_stream = io.BytesIO()
            doc.save(pdf_stream)
            doc.close()
            modified_pdf_content = base64.b64encode(pdf_stream.getvalue())
            if not self.ccew_file:
                self.env['worksheet.history'].sudo().create({
                    'worksheet_id': self.id,
                    'user_id': self.env.user.id,
                    'changes': 'Create CCEW Documents',
                    'details': 'CCEW Documents has been successfully created.',
                })
                model_id = self.env['ir.model'].search([('model', '=', self._name)], limit=1).id
                self.env['worksheet.notification'].sudo().create([{
                    'author_id': self.env.user.id,
                    'team_id': self.team_lead_id.id,
                    'model_id': model_id,
                    'res_id': self.id,
                    'date': datetime.now(),
                    'subject': 'Create CCEW Documents',
                    'body': '{} CCEW Documents has been successfully created.'.format(self.name),
                }])
            else:
                self.env['worksheet.history'].sudo().create({
                    'worksheet_id': self.id,
                    'user_id': self.env.user.id,
                    'changes': 'Updated CCEW Documents',
                    'details': ' CCEW Documents has been successfully Updated.',
                })
            self.ccew_file = None
            self.task_id.x_studio_ccew = modified_pdf_content

    def action_create_swms(self):
        pdf_file_name = (self.name + '-' + 'SWMS_document').replace('.', '').replace('/','_') + '.pdf'
        pdf_content = self.env['ir.actions.report']._render_qweb_pdf("beyond_worksheet.action_report_swms_report", self.id)[0]  # Get PDF content
        report_vals = {
            'name': pdf_file_name,
            'type': 'binary',
            'datas': base64.b64encode(pdf_content),
            'res_model': 'task.worksheet',
            'res_id': self.id,
            'mimetype': 'application/pdf',
        }
        res = self.env['ir.attachment'].sudo().create(report_vals)
        self.write({'swms_file': res.datas})

    def action_test_swms(self):
        return self.env.ref(
            'beyond_worksheet.action_report_swms_report').report_action(self)

