# -*- coding: utf-8 -*-
from odoo import fields, models
from geopy.geocoders import Nominatim
from math import radians, sin, cos, sqrt, atan2



class StockLot(models.Model):
    _inherit = "stock.lot"

    image = fields.Image(string='Image', store=True)
    state = fields.Selection([('draft', 'Draft'),('invalid', 'Invalid'),
                              ('verifying', 'Verifying'), ('verified', 'Verified')],
                            string='State', required=True, default='draft', readonly=True)
    type = fields.Selection([('panel', 'Panel'), ('inverter', 'Inverter'),('battery', 'Battery'),
                             ],string='Type')
    verification_time = fields.Datetime(string='Verification Time')
    worksheet_id = fields.Many2one('task.worksheet')
    user_id = fields.Many2one('res.users', string='User')
    member_id = fields.Many2one('team.member', string='Team Member')
    location = fields.Text(string='Location')
    categ_id = fields.Many2one('product.category', related='product_id.categ_id')
    is_checklist = fields.Boolean(string='checklist', default=False)
    latitude = fields.Float(string='Latitude', digits=(10, 7))
    longitude = fields.Float(string='Longitude', digits=(10, 7))
    is_location_validate = fields.Boolean(string='Location Validation', readonly=True)

    def write(self, vals):
        res = super(StockLot, self).write(vals)
        if self.worksheet_id and self.type and not self.is_checklist:
            self.env['worksheet.history'].sudo().create({
                'worksheet_id': self.worksheet_id.id,
                'user_id': self.user_id.id if self.user_id else False,
                'member_id': self.member_id.id if self.member_id else False,
                'changes': 'Updated Serial Number',
                'details': '{} Serial Number ({}) has been updated successfully.'.format(self.type,self.name),
            })
            self.is_checklist = True
        for val in vals:
            if self.worksheet_id and self.type and val == 'image':
                self.env['documents.document'].create({
                    'owner_id': self.user_id.id if self.user_id else False,
                    'team_id': self.member_id.id if self.member_id else False,
                    'datas': self.image,
                    'name':"{}({})".format(self.product_id.name, self.name),
                    'location': self.location,
                    'folder_id': self.env.ref('beyond_worksheet.documents_project_folder_Worksheet').id,
                    'res_model': 'task.worksheet',
                    'res_id': self.worksheet_id.id,
                })
            if val == 'location':
                self.haversine()
        return res

    def haversine(self):
        location = self.get_coordinates()
        R = 6371000
        lat1 = location.latitude
        lon1 =location.longitude
        lat2 = self.latitude
        lon2 = self.longitude
        lat1_rad, lon1_rad = radians(lat1), radians(lon1)
        lat2_rad, lon2_rad = radians(lat2), radians(lon2)
        delta_lat = lat2_rad - lat1_rad
        delta_lon = lon2_rad - lon1_rad
        a = sin(delta_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        distance = R * c
        if distance <= 200:
            self.is_location_validate = True
        else:
            self.is_location_validate = False

    def get_coordinates(self):
        geolocator = Nominatim(user_agent="myGeocoder")
        address = self.worksheet_id.site_address
        # Get the location
        location = geolocator.geocode(address)
        if location:
            print(f"Latitude: {location.latitude}, Longitude: {location.longitude}")
            return location
        else:
            print("Address not found. Please check the address format.")
