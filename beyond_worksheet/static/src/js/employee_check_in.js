/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";


publicWidget.registry.MemberPortal = publicWidget.Widget.extend({
    selector: '.member_portal',  // Replace with the class/id of the template element
        start: function () {
            this._super.apply(this, arguments);
            $('#submit_button').prop('disabled', true);
        },
        events: {
            'keyup #unique_member_id': '_onChangeMember',
        },
        async _onChangeMember(ev) {
            var result = await jsonrpc('/check/member',  {
                        'member_id' :ev.target.value
                        })
            if(result.exists == false){
                $('#validation_message').text('Invalid Employee ID.');
                console.log($('#member'))
                $('#member').val(false);
                $('#submit_button').prop('disabled', true);

            }
            else{
                $('#validation_message').text('');
                console.log('workseet',$('#worksheet_id')[0].value)
                $('#submit_button').prop('disabled', false);
                $('#checkin_form').attr('action', '/my/questions/' + $('#worksheet_id')[0].value+'/'+ result.member_id);
                console.log('form',$('#checkin_form'))
                $('#member').val(result.member_id);
            }
        }
});












//
//let previousX = 0;
//let previousY = 0;
//let isMoving = false;
//let KeyPress = false
//let startTime = 0;
//let lastKeyPressTime = 0;
//const movementThreshold = 40; // Minimum distance in pixels
//const movementDuration = 30000; // Minimum movement duration in milliseconds
//
//document.onmousemove = (event) => {
//    const currentX = event.clientX;
//    const currentY = event.clientY;
//    const distance = Math.sqrt(Math.pow(currentX - previousX, 2) + Math.pow(currentY - previousY, 2));
//    if (distance >= movementThreshold) {
//        isMoving = true;
//        startTime = Date.now();
//    }
//    previousX = currentX;
//    previousY = currentY;
//};
//
//document.onclick = (event) => {
//    isMoving =true
//};
//
//document.onkeypress = () => {
//    KeyPress = true;
//    lastKeyPressTime = Date.now();
//};
//let employee = false
//jsonrpc('/is_employee',  {
//    'user' :session.uid,
//}).then((res)=>{
//    employee = res
//})
//var users_register ={}
//
//setInterval(function() {
//    if (employee){
//        const checkinInfo = document.querySelector("[aria-label='Attendance']")
//        if ((isMoving || KeyPress) && (Date.now() - startTime < movementDuration ||  (Date.now() - lastKeyPressTime) < 30000)) {
//            checkinInfo.classList.add('text-success');
//            checkinInfo.classList.remove('text-danger');
//            startTime = Date.now()
//            jsonrpc('/get_user_attendance',  {
//                        'uid' :session.uid,
//                }).then((data) => {
//                    console.log('check_in',data)
//                    if (!data){
//                        navigator.geolocation.getCurrentPosition(
//                            async ({coords: {latitude, longitude}}) => {
//                                await jsonrpc("/hr_attendance/systray_check_in_out", {
//                                    latitude,
//                                    longitude
//                                })
//                            },
//                            async err => {
//                                await jsonrpc("/hr_attendance/systray_check_in_out")
//                            },
//                            {
//                                enableHighAccuracy: true,
//                            })
//                        }
//                })
//        }
//        else{
//            checkinInfo.classList.add('text-danger');
//            checkinInfo.classList.remove('text-success');
//            jsonrpc('/get_user_attendance',  {
//                        'uid' :session.uid,
//                }).then((data) => {
//                    if (data) {
//                        console.log('check_in',data)
//                        console.log('>>>>>>>>',data)
//                        if (!isIosApp()) {
//                            navigator.geolocation.getCurrentPosition(
//                            async ({coords: {latitude, longitude}}) => {
//                                jsonrpc("/hr_attendance/systray_check_in_out", {
//                                    latitude,
//                                    longitude
//                                })
//                            },
//                            async err => {
//                                jsonrpc("/hr_attendance/systray_check_in_out")
//                            },
//                            {
//                                enableHighAccuracy: true,
//                            }
//                        )}
//                        else {
//                            jsonrpc("/hr_attendance/systray_check_in_out")
//                        }
//                    }
//                })
//        }
//    }
//}, 30000);