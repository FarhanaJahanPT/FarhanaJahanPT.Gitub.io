# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from datetime import datetime
from geopy.geocoders import Nominatim


class OwnerSignature(http.Controller):

    @http.route('/my/task/<int:task_id>/signature', type="http", auth="public", website=True,
                sitemap=False)
    def owner_signature_forms(self, task_id, **kw):
        if task_id:
            task = request.env['project.task'].sudo().browse(int(task_id))
        else:
            return http.request.not_found()
            # task = request.env['project.task'].sudo().browse(22537)
        return request.render("beyond_worksheet.owner_signature_template", {'task': task, })

    @http.route('/my/worksheet/<int:user_id>/<int:worksheet_id>/', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_portal(self, user_id, worksheet_id, **kw):
        print('user_id', user_id, worksheet_id)

        # if task_id:
        #     task = request.env['project.task'].sudo().browse(int(task_id))
        # else:
        #     return http.request.not_found()
        # task = request.env['project.task'].sudo().browse(22537)
        return request.render("beyond_worksheet.worksheet_members_template",
                              {'user': user_id, 'worksheet': worksheet_id})

    @http.route('/worksheet/members/checkin/<int:user_id>/<int:worksheet_id>', type="http", auth="public", website=True,
                sitemap=False)
    def worksheet_members_check_in(self, user_id, worksheet_id, **kw):
        geoLoc = Nominatim(user_agent="GetLoc")
        # print('+++++++++', geoLoc.)
        check_in = request.env['worksheet.attendance'].sudo().create({
            'type': 'check_in',
            'user_id': user_id,
            'worksheet_id': worksheet_id
        })
        # if task_id:
        #     task = request.env['project.task'].sudo().browse(int(task_id))
        # else:
        #     return http.request.not_found()
        # task = request.env['project.task'].sudo().browse(22537)
        return "hiii"

    @http.route('/my/task/<int:task_id>/signature/check', type='json',
                website=True)
    def task_signature_check(self, task_id, name=None, signature=None, **kwargs):
        task = request.env['project.task'].sudo().browse(task_id)
        if not task.exists():
            return http.request.not_found()
        task.customer_name = name
        task.customer_signature = signature
        task.date_worksheet_client_signature = datetime.now()
        return {
            'force_refresh': True,
        }
