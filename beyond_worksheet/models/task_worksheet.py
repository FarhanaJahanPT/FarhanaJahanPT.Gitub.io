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
from odoo import api, fields, models,_
from odoo.modules.module import get_module_resource


class WorkSheet(models.Model):
    _name = 'task.worksheet'
    _description = "Worksheet"
    _inherit = ['mail.thread', 'mail.activity.mixin']

    partner_id = fields.Many2one(string='Customer', related='task_id.partner_id', tracking=True)
    name = fields.Char("Name", default=lambda self: _('New'))
    task_id = fields.Many2one('project.task', string='Task', tracking=True)
    sale_id = fields.Many2one('sale.order', string='Sale Order', related="task_id.sale_order_id", tracking=True)

    panel_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                    string='Panel Serial Number', domain=[('type', '=', 'panel')], readonly=True)

    inverter_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                       string='Inverter Serial Number', domain=[('type', '=', 'inverter')],
                                       readonly=True)
    battery_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                      string='Battery Serial Number', domain=[('type', '=', 'battery')], readonly=True)

    attendance_qr_ids = fields.One2many('attendance.qr','worksheet_id')
    panel_count = fields.Integer(string='Panel Count', compute='_compute_order_count', store=True, default=0, tracking=True)
    inverter_count = fields.Integer(string='Inverter Count', compute='_compute_order_count', store=True, default=0, tracking=True)
    battery_count = fields.Integer(string='Battery Count', compute='_compute_order_count', store=True, default=0, tracking=True)

    checklist_item_ids = fields.One2many('installation.checklist.item', 'worksheet_id',
                                         domain=[('checklist_id.selfie_type', '=', 'null')])
    service_item_ids = fields.One2many('service.checklist.item', 'worksheet_id',
                                       domain=[('service_id.selfie_type', '=', 'null')])
    is_checklist = fields.Boolean(string='Checklist', compute='_compute_is_checklist', store=True, tracking=True)
    checklist_count = fields.Integer(string='Checklist Count', compute='_compute_is_checklist', store=True, tracking=True)
    is_individual = fields.Boolean(string='Individual', tracking=True)
    assigned_users = fields.Many2many('res.users', string='Assigned Users', tracking=True)
    witness_signature = fields.Char(string="Witness Signature", copy=False, tracking=True)
    witness_signature_date = fields.Datetime(string="Witness Signature Date", copy=False, tracking=True)
    x_studio_type_of_service = fields.Selection(string='Type of Service',
                                                related='sale_id.x_studio_type_of_service', readonly=True, tracking=True)
    worksheet_attendance_ids = fields.One2many('worksheet.attendance', 'worksheet_id', string='Worksheet Attendance')
    invoice_count = fields.Integer(string="Invoice Count", compute='_compute_invoice_count', help='Total invoice count', tracking=True)
    is_testing_required = fields.Boolean("Testing needed", tracking=True)
    is_ces_activity_created = fields.Boolean("CES Activity created", tracking=True)
    is_ccew = fields.Boolean('Is CCEW', compute='_compute_is_ccew', tracking=True)
    ccew_sequence = fields.Char('Sequence', tracking=True)
    ccew_file = fields.Binary(string='CCEW', related='task_id.x_studio_ccew', store=True)
    electrical_license_number = fields.Char(
        related='task_id.x_studio_proposed_team.x_studio_act_electrical_licence_number', tracking=True)
    is_site_induction = fields.Boolean(string='Site Induction', tracking=True)
    worksheet_history_ids = fields.One2many('worksheet.history','worksheet_id', readonly=True)

    @api.model_create_multi
    def create(self, vals_list):
        """Function to create sequence"""
        for vals in vals_list:
            if not vals.get('name') or vals['name'] == _('New'):
                vals['name'] = self.env['ir.sequence'].next_by_code('task.worksheet') or _('New')
        res = super(WorkSheet, self).create(vals_list)
        return res

    # def write(self, vals):
    #     res = super().write(vals)
    #     print(vals,'aaaaaaaaaaaaaaaaaaaaaaaaaaaa')
    #     operation_team = self.env['hr.employee'].search([('department_id', '=', self.env.ref('beyond_worksheet.dep_operations').id)]).user_id
    #     if self.battery_count or self.inverter_count and self.is_testing_required and not self.is_ces_activity_created:
    #         operation_team = self.env['hr.employee'].search(
    #             [('department_id', '=', self.env.ref('beyond_worksheet.dep_operations').id)]).user_id
    #         for member in operation_team:
    #             self.sudo().activity_schedule(
    #                 'mail.mail_activity_data_todo', fields.Datetime.now(),
    #                 "Need To Generate CES", user_id=member.id)
    #         self.is_ces_activity_created = True if operation_team else False
    #     if self.ccew_file and not self.ccew_sequence:
    #         seq = self.env['ir.sequence'].next_by_code('ccew.sequence')
    #         license = '-' + (str(self.electrical_license_number) + '/' if self.electrical_license_number else '' ) + str(
    #             self.task_id.x_studio_proposed_team.name) + '-'
    #         self.ccew_sequence = seq.replace('--', license)
        # self.env['mail.message'].sudo().create([{
        #     'author_id': self.env.user.partner_id.id,
        #     'subtype_id': self.env.ref('mail.mt_comment').id,
        #     'model': 'task.worksheet',
        #     'res_id': self.id,
        #     'date': datetime.now(),
        #     'reply_to': False,
        #     'body': 'aaaaaaaaaaaaaaaaaaa',
        # }])
        # return res

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

    @api.depends('partner_id', 'is_individual', 'is_testing_required')
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

    def _compute_invoice_count(self):
        """Function to count invoice"""
        for record in self:
            record.invoice_count = self.env['account.move'].search_count([('invoice_origin', '=', self.name)])

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
            if worksheet_id.is_individual:
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
                    invoice = self.env['account.move'].create([{
                        'name': self.env['ir.sequence'].next_by_code('rcti.invoice'),
                        'move_type': 'in_invoice',
                        'partner_id': user_id.partner_id.id,
                        'invoice_origin': worksheet_id.name,
                        'date': worksheet_id.task_id.planned_date_begin,
                        'invoice_date_due': today.date() + timedelta(days=5),
                        'invoice_line_ids': vals
                    }])
                    print(invoice)

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
                    move = move_line_ids.create(move_line_id)
                    print(move)

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
            if self.task_id.x_studio_proposed_team:
                partner_id = self.task_id.x_studio_proposed_team.partner_id
                address = partner_id.street
                name = partner_id.name
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
                page.insert_text((47,697), partner_id.email, fontsize=10,color=(0, 0, 0))
                page.insert_text((470,697), partner_id.mobile if partner_id.mobile else partner_id.phone, fontsize=10,color=(0, 0, 0))
                page.insert_text((309,727), self.task_id.x_studio_proposed_team.x_studio_nsw_contractor_licence_number, fontsize=10,color=(0, 0, 0))
                page.insert_text((451,727), str(self.task_id.x_studio_proposed_team.x_studio_nsw_contractor_licence_expiry_date), fontsize=10,color=(0, 0, 0))
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
            if self.is_testing_required and self.task_id.x_studio_proposed_team:
                page.insert_image((237,281,252,292), filename=image_path)
                page.insert_text((47, 322), first_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 322), last_name, fontsize=10,color=(0, 0, 0))
                page.insert_text((176, 351), unit_value_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 351), number_1, fontsize=10, color=(0, 0, 0))
                page.insert_text((47, 380), remaining_address_1, fontsize=10,color=(0, 0, 0))
                page.insert_text((47, 410), partner_id.city, fontsize=10,color=(0, 0, 0))
                page.insert_text((298, 410), partner_id.state_id.code, fontsize=10,color=(0, 0, 0))
                page.insert_text((469, 410), partner_id.zip, fontsize=10,color=(0, 0, 0))
                page.insert_text((47, 438), partner_id.email, fontsize=10,color=(0, 0, 0))
                page.insert_text((469, 438),partner_id.mobile if partner_id.mobile else partner_id.phone,fontsize=10, color=(0, 0, 0))
                page.insert_text((309, 468),self.task_id.x_studio_proposed_team.x_studio_nsw_contractor_licence_number,fontsize=10, color=(0, 0, 0))
                page.insert_text((452, 467),str(self.task_id.x_studio_proposed_team.x_studio_nsw_contractor_licence_expiry_date),fontsize=10, color=(0, 0, 0))
            pdf_stream = io.BytesIO()
            doc.save(pdf_stream)
            doc.close()
            modified_pdf_content = base64.b64encode(pdf_stream.getvalue())
            self.ccew_file = modified_pdf_content
