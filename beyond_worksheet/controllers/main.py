# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from datetime import datetime

class OwnerSignature(http.Controller):

    @http.route('/my/task/<int:task_id>/signature', type="http", auth="public", website=True,
                sitemap=False)
    def owner_signature_forms(self, task_id, **kw):
        if task_id:
            task = request.env['project.task'].sudo().browse(int(task_id))
        else:
            return http.request.not_found()
            # task = request.env['project.task'].sudo().browse(22537)
        return request.render("beyond_worksheet.owner_signature_template",{'task': task,})

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
