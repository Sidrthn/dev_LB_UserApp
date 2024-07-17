<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Models\User;
use Carbon\CarbonInterval;
use Illuminate\Http\Request;
use App\CentralLogics\Helpers;
use Illuminate\Support\Carbon;
use App\Mail\EmailVerification;
use App\Mail\LoginVerification;
use App\Models\BusinessSetting;
use App\CentralLogics\SMS_module;
use App\Models\WalletTransaction;
use App\Models\EmailVerifications;
use Illuminate\Support\Facades\DB;
use App\CentralLogics\CustomerLogic;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Mail;
use Modules\Gateways\Traits\SmsGateway;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class CustomerAuthController extends Controller
{
    public function verify_phone(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required',
            'otp' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }
        $user = User::where('phone', $request->phone)->first();
        if ($user) {
//            if ($user->is_phone_verified) {
//                $token = $user->createToken('RestaurantCustomerAuth')->accessToken;
//                return response()->json(['token' => $token, 'is_phone_verified' => true, 'user' => $user], 200);
//            }

            $data = DB::table('phone_verifications')->where([
                'phone' => $request['phone'],
                'token' => $request['otp'],
            ])->first();

            if (!$data) {
                return response()->json([
                    'message' => translate('messages.phone_number_and_otp_not_matched')
                ], 404);
            }
            if ($data) {
                DB::table('phone_verifications')->where([
                    'phone' => $request['phone'],
                    'token' => $request['otp'],
                ])->delete();

                $user->is_phone_verified = 1;
                $user->save();
                $token = $user->createToken('RestaurantCustomerAuth')->accessToken;

                return response()->json([
                    'message' => translate('messages.phone_number_varified_successfully'),
                    'otp' => 'inactive',
                    'user' => $user,
                    'token' => $token,
                    ], 200);
            } else {
                $max_otp_hit = 5;
                $max_otp_hit_time = 60; // seconds
                $temp_block_time = 600; // seconds

                $verification_data = DB::table('phone_verifications')->where('phone', $request['phone'])->first();

                if (isset($verification_data)) {

                    if (isset($verification_data->temp_block_time) && Carbon::parse($verification_data->temp_block_time)->DiffInSeconds() <= $temp_block_time) {
                        $time = $temp_block_time - Carbon::parse($verification_data->temp_block_time)->DiffInSeconds();

                        $errors = [];
                        array_push($errors, [
                            'code' => 'otp_block_time',
                            'message' => translate('messages.please_try_again_after_') . CarbonInterval::seconds($time)->cascade()->forHumans()
                        ]);
                        return response()->json([
                            'errors' => $errors
                        ], 405);
                    }

                    if ($verification_data->is_temp_blocked == 1 && Carbon::parse($verification_data->updated_at)->DiffInSeconds() >= $max_otp_hit_time) {
                        DB::table('phone_verifications')->updateOrInsert(
                            ['phone' => $request['phone']],
                            [
                                'otp_hit_count' => 0,
                                'is_temp_blocked' => 0,
                                'temp_block_time' => null,
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]
                        );
                    }

                    if ($verification_data->otp_hit_count >= $max_otp_hit && Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $max_otp_hit_time && $verification_data->is_temp_blocked == 0) {

                        DB::table('phone_verifications')->updateOrInsert(
                            ['phone' => $request['phone']],
                            [
                                'is_temp_blocked' => 1,
                                'temp_block_time' => now(),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]
                        );
                        $errors = [];
                        array_push($errors, ['code' => 'otp_temp_blocked', 'message' => translate('messages.Too_many_attemps')]);
                        return response()->json([
                            'errors' => $errors
                        ], 405);
                    }

                }


                DB::table('phone_verifications')->updateOrInsert(
                    ['phone' => $request['phone']],
                    [
                        'otp_hit_count' => DB::raw('otp_hit_count + 1'),
                        'updated_at' => now(),
                        'temp_block_time' => null,
                    ]
                );

                return response()->json([
                    'message' => translate('messages.phone_number_and_otp_not_matched')
                ], 404);
            }
        }
        return response()->json([
            'message' => translate('messages.not_found')
        ], 404);
    }

    public function check_email(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|unique:users'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }


        if (BusinessSetting::where(['key' => 'email_verification'])->first()->value) {
            $token = rand(1000, 9999);
            DB::table('email_verifications')->insert([
                'email' => $request['email'],
                'token' => $token,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $mail_status = Helpers::get_mail_status('registration_otp_mail_status_user');
            if (config('mail.status') && $mail_status == '1') {
                $user = User::where('email', $request['email'])->first();
                Mail::to($request['email'])->send(new EmailVerification($token,$user->f_name));
            }
            return response()->json([
                'message' => 'Email is ready to register',
                'token' => 'active'
            ], 200);
        } else {
            return response()->json([
                'message' => 'Email is ready to register',
                'token' => 'inactive'
            ], 200);
        }
    }

    public function verify_email(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $verify = EmailVerifications::where(['email' => $request['email'], 'token' => $request['token']])->first();

        if (isset($verify)) {
            $verify->delete();
            return response()->json([
                'message' => translate('messages.token_varified'),
            ], 200);
        }

        $errors = [];
        array_push($errors, ['code' => 'token', 'message' => translate('messages.token_not_found')]);
        return response()->json(
            ['errors' => $errors],
            404
        );
    }

//    public function register(Request $request)
//    {
//        $validator = Validator::make($request->all(), [
//            'f_name' => 'required',
//            'l_name' => 'required',
//            'email' => 'required|unique:users',
//            'phone' => 'required|unique:users',
//            'password' => ['required', Password::min(8)->mixedCase()->letters()->numbers()->symbols()->uncompromised()],
//        ], [
//            'f_name.required' => 'The first name field is required.',
//            'l_name.required' => 'The last name field is required.',
//        ]);
//
//        if ($validator->fails()) {
//            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
//        }
//        $ref_by= null ;
//        $customer_verification = BusinessSetting::where('key', 'customer_verification')->first()->value;
//
//        if($request->ref_code) {
//            $ref_status = BusinessSetting::where('key','ref_earning_status')->first()->value;
//            if ($ref_status != '1') {
//                return response()->json(['errors'=>Helpers::error_formater('ref_code', translate('messages.referer_disable'))], 403);
//            }
//
//            $referar_user = User::where('ref_code', '=', $request->ref_code)->first();
//            if (!$referar_user || !$referar_user->status) {
//                return response()->json(['errors'=>Helpers::error_formater('ref_code',translate('messages.referer_code_not_found'))], 405);
//            }
//
//            if(WalletTransaction::where('reference', $request->phone)->first()) {
//                return response()->json(['errors'=>Helpers::error_formater('phone',translate('Referrer code already used'))], 203);
//            }
//
//            // $ref_code_exchange_amt = BusinessSetting::where('key','ref_earning_exchange_rate')->first()->value;
//
//            // $refer_wallet_transaction = CustomerLogic::create_wallet_transaction($referar_user->id, $ref_code_exchange_amt, 'referrer',$request->phone);
//            //dd($refer_wallet_transaction);
//            // try{
//            //     if(config('mail.status')) {
//            //         Mail::to($referar_user->email)->send(new \App\Mail\AddFundToWallet($refer_wallet_transaction));
//            //     }
//            // }catch(\Exception $ex)
//            // {
//            //     info($ex->getMessage());
//            // }
//
//            $ref_by= $referar_user->id;
//        }
//
//        $user = User::create([
//            'f_name' => $request->f_name,
//            'l_name' => $request->l_name,
//            'email' => $request->email,
//            'phone' => $request->phone,
//            'ref_by' =>   $ref_by,
//            'password' => bcrypt($request->password),
//        ]);
//        $user->ref_code = Helpers::generate_referer_code($user);
//        $user->save();
//
//
//
//        $token = $user->createToken('RestaurantCustomerAuth')->accessToken;
//
//        if($customer_verification && env('APP_MODE') !='demo')
//        {
//
//            // $interval_time = BusinessSetting::where('key', 'otp_interval_time')->first();
//            // $otp_interval_time= isset($interval_time) ? $interval_time->value : 20;
//            $otp_interval_time= 60; //seconds
//            $verification_data= DB::table('phone_verifications')->where('phone', $request['phone'])->first();
//
//            if(isset($verification_data) &&  Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $otp_interval_time){
//                $time= $otp_interval_time - Carbon::parse($verification_data->updated_at)->DiffInSeconds();
//                $errors = [];
//                array_push($errors, ['code' => 'otp', 'message' =>  translate('messages.please_try_again_after_').$time.' '.translate('messages.seconds')]);
//                return response()->json([
//                    'errors' => $errors
//                ], 405);
//            }
//
//            $otp = rand(1000, 9999);
//            DB::table('phone_verifications')->updateOrInsert(['phone' => $request['phone']],
//                [
//                'token' => $otp,
//                'otp_hit_count' => 0,
//                'created_at' => now(),
//                'updated_at' => now(),
//                ]);
//                $mail_status = Helpers::get_mail_status('registration_otp_mail_status_user');
//                if (config('mail.status') && $mail_status == '1') {
//                    Mail::to($request['email'])->send(new EmailVerification($otp,$request->f_name));
//                }
//            //for payment and sms gateway addon
//            $published_status = 0;
//            $payment_published_status = config('get_payment_publish_status');
//            if (isset($payment_published_status[0]['is_published'])) {
//                $published_status = $payment_published_status[0]['is_published'];
//            }
//
//            if($published_status == 1){
//                $response = SmsGateway::send($request['phone'],$otp);
//            }else{
//                $response = SMS_module::send($request['phone'],$otp);
//            }
//            if($response != 'success')
//            {
//                $errors = [];
//                array_push($errors, ['code' => 'otp', 'message' => translate('messages.faield_to_send_sms')]);
//                return response()->json([
//                    'errors' => $errors
//                ], 405);
//            }
//        }
//        try
//        {
//            $mail_status = Helpers::get_mail_status('registration_mail_status_user');
//            if (config('mail.status') && $request->email && $mail_status == '1') {
//                Mail::to($request->email)->send(new \App\Mail\CustomerRegistration($request->f_name . ' ' . $request->l_name));
//            }
//        }
//        catch(\Exception $ex)
//        {
//            info($ex->getMessage());
//        }
//        return response()->json(['token' => $token, 'is_phone_verified' => 0, 'phone_verify_end_url' => "api/v1/auth/verify-phone"], 200);
//    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'f_name' => 'required',
            'l_name' => 'nullable',
            'email' => 'required|unique:users',
            'phone' => 'required|unique:users',
        ], [
            'f_name.required' => 'The first name field is required.',
            'phone.required' => 'Phone is required.',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $ref_by = null;
        $customer_verification = BusinessSetting::where('key', 'customer_verification')->first()->value;

        if ($request->ref_code) {
            $ref_status = BusinessSetting::where('key', 'ref_earning_status')->first()->value;
            if ($ref_status != '1') {
                return response()->json(['errors' => Helpers::error_formater('ref_code', translate('messages.referer_disable'))], 403);
            }

            $referar_user = User::where('ref_code', '=', $request->ref_code)->first();
            if (!$referar_user || !$referar_user->status) {
                return response()->json(['errors' => Helpers::error_formater('ref_code', translate('messages.referer_code_not_found'))], 405);
            }

            if (WalletTransaction::where('reference', $request->phone)->first()) {
                return response()->json(['errors' => Helpers::error_formater('phone', translate('Referrer code already used'))], 203);
            }

            $ref_by = $referar_user->id;
        }

        $user = User::create([
            'f_name' => $request->f_name,
            'l_name' => $request->l_name,
            'email' => $request->email,
            'phone' => $request->phone,
            'ref_by' => $ref_by,
        ]);
        $user->ref_code = Helpers::generate_referer_code($user);
        $user->save();

        $token = $user->createToken('RestaurantCustomerAuth')->accessToken;

        if ($customer_verification && env('APP_MODE') != 'demo') {
            $otp_interval_time = 60; // seconds
            $verification_data = DB::table('phone_verifications')->where('phone', $request['phone'])->first();

            if (isset($verification_data) && Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $otp_interval_time) {
                $time = $otp_interval_time - Carbon::parse($verification_data->updated_at)->DiffInSeconds();
                $errors = [];
                array_push($errors, ['code' => 'otp', 'message' => translate('messages.please_try_again_after_') . $time . ' ' . translate('messages.seconds')]);
                return response()->json([
                    'errors' => $errors
                ], 405);
            }

            $otp = rand(1000, 9999);
            DB::table('phone_verifications')->updateOrInsert(['phone' => $request['phone']],
                [
                    'token' => $otp,
                    'otp_hit_count' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

            $mail_status = Helpers::get_mail_status('registration_otp_mail_status_user');
            if (config('mail.status') && $mail_status == '1') {
                Mail::to($request['email'])->send(new EmailVerification($otp, $request->f_name));
            }

            // For payment and SMS gateway addon
            $published_status = 0;
            $payment_published_status = config('get_payment_publish_status');
            if (isset($payment_published_status[0]['is_published'])) {
                $published_status = $payment_published_status[0]['is_published'];
            }

            if ($published_status == 1) {
                $response = SmsGateway::send($request['phone'], $otp);
            } else {
                $response = SMS_module::send($request['phone'], $otp);
            }
            if ($response != 'success') {
                $errors = [];
                array_push($errors, ['code' => 'otp', 'message' => translate('messages.failed_to_send_sms')]);
                return response()->json([
                    'errors' => $errors
                ], 405);
            }
        }

        try {
            $mail_status = Helpers::get_mail_status('registration_mail_status_user');
            if (config('mail.status') && $request->email && $mail_status == '1') {
                Mail::to($request->email)->send(new \App\Mail\CustomerRegistration($request->f_name . ' ' . $request->l_name));
            }
        } catch (\Exception $ex) {
            info($ex->getMessage());
        }

        return response()->json(['token' => $token, 'is_phone_verified' => 0, 'phone_verify_end_url' => "api/v1/auth/verify-phone"], 200);
    }

    public function authenticate(Request $request)
    {
        // Validate phone number
        $validator = Validator::make($request->all(), [
            'phone' => 'required',
        ], [
            'phone.required' => 'Phone is required.',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        // Check if user exists
        $user = User::where('phone', $request->phone)->first();
        $customer_verification = BusinessSetting::where('key', 'customer_verification')->first()->value;

        if ($user) {
            // User exists, send OTP for login
            $token = $user->createToken('RestaurantCustomerAuth')->accessToken;
            $this->sendOtp($request->phone, $user->email, $user->f_name, $customer_verification);

            return response()->json(['token' => $token, 'is_phone_verified' => 0, 'phone_verify_end_url' => "api/v1/auth/verify-phone"], 200);
        } else {
            // User does not exist, require additional information to create user
            $validator = Validator::make($request->all(), [
                'f_name' => 'required',
                'l_name' => 'nullable',
                'email' => 'nullable|unique:users',
            ], [
                'f_name.required' => 'The first name field is required.',
            ]);

            if ($validator->fails()) {
                return response()->json(['errors' => Helpers::error_processor($validator), "message" => "User Not Found", "success" => false], 403);
            }


            $ref_by = null;
            if ($request->ref_code) {
                $ref_status = BusinessSetting::where('key', 'ref_earning_status')->first()->value;
                if ($ref_status != '1') {
                    return response()->json(['errors' => Helpers::error_formater('ref_code', translate('messages.referer_disable'))], 403);
                }

                $referar_user = User::where('ref_code', '=', $request->ref_code)->first();
                if (!$referar_user || !$referar_user->status) {
                    return response()->json(['errors' => Helpers::error_formater('ref_code', translate('messages.referer_code_not_found'))], 405);
                }

                if (WalletTransaction::where('reference', $request->phone)->first()) {
                    return response()->json(['errors' => Helpers::error_formater('phone', translate('Referrer code already used'))], 203);
                }

                $ref_by = $referar_user->id;
            }

            // Create new user
            $newUser = User::create([
                'f_name' => $request->f_name,
                'l_name' => $request->l_name,
                'email' => $request->email,
                'phone' => $request->phone,
                'cod' => 1,
                'ref_by' => $ref_by,
            ]);
            $newUser->ref_code = Helpers::generate_referer_code($newUser);
            $newUser->save();

            $token = $newUser->createToken('RestaurantCustomerAuth')->accessToken;
            $this->sendOtp($request->phone, $request->email, $request->f_name, $customer_verification);

            return response()->json(['token' => $token, 'is_phone_verified' => 0, 'phone_verify_end_url' => "api/v1/auth/verify-phone"], 200);
        }
    }

    private function sendOtp($phone, $email, $name, $customer_verification)
    {
        if ($customer_verification && env('APP_MODE') != 'demo') {
            $otp_interval_time = 60; // seconds
            $verification_data = DB::table('phone_verifications')->where('phone', $phone)->first();

            if (isset($verification_data) && Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $otp_interval_time) {
                $time = $otp_interval_time - Carbon::parse($verification_data->updated_at)->DiffInSeconds();
                $errors = [];
                array_push($errors, ['code' => 'otp', 'message' => translate('messages.please_try_again_after_') . $time . ' ' . translate('messages.seconds')]);
                return response()->json(['errors' => $errors], 405);
            }

            $otp = rand(1000, 9999);
            DB::table('phone_verifications')->updateOrInsert(['phone' => $phone], [
                'token' => $otp,
                'otp_hit_count' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $mail_status = Helpers::get_mail_status('registration_otp_mail_status_user');
            if (config('mail.status') && $mail_status == '1') {
                Mail::to($email)->send(new EmailVerification($otp, $name));
            }

            // For payment and SMS gateway addon
            $published_status = 0;
            $payment_published_status = config('get_payment_publish_status');
            if (isset($payment_published_status[0]['is_published'])) {
                $published_status = $payment_published_status[0]['is_published'];
            }

            if ($published_status == 1) {
                $response = SmsGateway::send($phone, $otp);
            } else {
                $response = SMS_module::send($phone, $otp);
            }

            if ($response != 'success') {
                $errors = [];
                array_push($errors, ['code' => 'otp', 'message' => translate('messages.failed_to_send_sms')]);
                return response()->json(['errors' => $errors], 405);
            }
        }
    }


    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'sometimes|nullable|email',
            'phone' => 'sometimes|nullable',
            'password' => 'required_if:email,null|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $credentials = [
            'password' => $request->password,
        ];

        if ($request->has('email')) {
            $credentials['email'] = $request->email;
        } elseif ($request->has('phone')) {
            $customer_verification = BusinessSetting::where('key', 'customer_verification')->first()->value;
            $credentials['phone'] = $request->phone;
            if ($customer_verification) {
                $otp_interval_time = 60; //seconds

                $verification_data = DB::table('phone_verifications')->where('phone', $request['phone'])->first();

                if (isset($verification_data) && Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $otp_interval_time) {

                    $time = $otp_interval_time - Carbon::parse($verification_data->updated_at)->DiffInSeconds();
                    $errors = [];
                    array_push($errors, ['code' => 'otp', 'message' => translate('messages.please_try_again_after_') . $time . ' ' . translate('messages.seconds')]);
                    return response()->json([
                        'errors' => $errors
                    ], 405);
                }

                $otp = rand(1000, 9999);
                DB::table('phone_verifications')->updateOrInsert(
                    ['phone' => $request['phone']],
                    [
                        'token' => $otp,
                        'otp_hit_count' => 0,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
                $mail_status = Helpers::get_mail_status('login_otp_mail_status_user');
                if (config('mail.status') && $mail_status == '1') {
                    Mail::to($user['email'])->send(new LoginVerification($otp, $user->f_name));
                }
                //for payment and sms gateway addon
                $published_status = 0;
                $payment_published_status = config('get_payment_publish_status');
                if (isset($payment_published_status[0]['is_published'])) {
                    $published_status = $payment_published_status[0]['is_published'];
                }

                if ($published_status == 1) {
                    $response = SmsGateway::send($request['phone'], $otp);
                } else {
                    $response = SMS_module::send($request['phone'], $otp);
                }

                if ($response != 'success') {
                    $errors = [];
                    array_push($errors, ['code' => 'otp', 'message' => translate('messages.faield_to_send_sms')]);
                    return response()->json([
                        'errors' => $errors
                    ], 405);
                }

                return response()->json(['is_phone_verified' => 0, 'phone_verify_end_url' => "api/v1/auth/verify-phone"], 200);
            }
        } else {
            return response()->json(['errors' => [['code' => 'auth-002', 'message' => translate('messages.Email_or_phone_required')]]], 403);
        }

        if (auth()->attempt($credentials)) {
            $user = auth()->user();
            $token = $user->createToken('RestaurantCustomerAuth')->accessToken;
            if (!$user->status) {
                return response()->json(['errors' => [['code' => 'auth-003', 'message' => translate('messages.your_account_is_blocked')]]], 403);
            }

            if ($request->guest_id && isset($user->id)) {

                $userStoreIds = Cart::where('user_id', $request->guest_id)
                    ->join('items', 'carts.item_id', '=', 'items.id')
                    ->pluck('items.store_id')
                    ->toArray();

                Cart::where('user_id', $user->id)
                    ->whereHas('item', function ($query) use ($userStoreIds) {
                        $query->whereNotIn('store_id', $userStoreIds);
                    })
                    ->delete();

                Cart::where('user_id', $request->guest_id)->update(['user_id' => $user->id, 'is_guest' => 0]);
            }

            return response()->json(['token' => $token, 'is_phone_verified' => $user->is_phone_verified, 'user' => $user], 200);
        } else {
            return response()->json(['errors' => [['code' => 'auth-001', 'message' => translate('messages.Unauthorized')]]], 401);
        }
    }


    public function loginss(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required',
            'password' => 'required|min:6'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $data = [
            'phone' => $request->phone,
            'password' => $request->password
        ];
        $customer_verification = BusinessSetting::where('key', 'customer_verification')->first()->value;
        if (auth()->attempt($data)) {
            $token = auth()->user()->createToken('RestaurantCustomerAuth')->accessToken;
            if (!auth()->user()->status) {
                $errors = [];
                array_push($errors, ['code' => 'auth-003', 'message' => translate('messages.your_account_is_blocked')]);
                return response()->json([
                    'errors' => $errors
                ], 403);
            }
            $user = auth()->user();
            if($customer_verification && !auth()->user()->is_phone_verified && env('APP_MODE') != 'demo')
            {

                // $interval_time = BusinessSetting::where('key', 'otp_interval_time')->first();
                // $otp_interval_time= isset($interval_time) ? $interval_time->value : 60;
                $otp_interval_time= 60; //seconds

                $verification_data= DB::table('phone_verifications')->where('phone', $request['phone'])->first();

                if(isset($verification_data) &&  Carbon::parse($verification_data->updated_at)->DiffInSeconds() < $otp_interval_time){

                    $time= $otp_interval_time - Carbon::parse($verification_data->updated_at)->DiffInSeconds();
                    $errors = [];
                    array_push($errors, ['code' => 'otp', 'message' =>  translate('messages.please_try_again_after_').$time.' '.translate('messages.seconds')]);
                    return response()->json([
                        'errors' => $errors
                    ], 405);
                }

                $otp = rand(1000, 9999);
                DB::table('phone_verifications')->updateOrInsert(['phone' => $request['phone']],
                    [
                    'token' => $otp,
                    'otp_hit_count' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                    ]);
                $mail_status = Helpers::get_mail_status('login_otp_mail_status_user');
                if (config('mail.status') && $mail_status == '1') {
                    Mail::to($user['email'])->send(new LoginVerification($otp,$user->f_name));
                }
                //for payment and sms gateway addon
                $published_status = 0;
                $payment_published_status = config('get_payment_publish_status');
                if (isset($payment_published_status[0]['is_published'])) {
                    $published_status = $payment_published_status[0]['is_published'];
                }

                if($published_status == 1){
                    $response = SmsGateway::send($request['phone'],$otp);
                }else{
                    $response = SMS_module::send($request['phone'],$otp);
                }
                // $response = 'qq';
                if($response != 'success')
                {
                    $errors = [];
                    array_push($errors, ['code' => 'otp', 'message' => translate('messages.faield_to_send_sms')]);
                    return response()->json([
                        'errors' => $errors
                    ], 405);
                }

            }
            if($user->ref_code == null && isset($user->id)){
                $ref_code = Helpers::generate_referer_code($user);
                DB::table('users')->where('phone', $user->phone)->update(['ref_code' => $ref_code]);
            }
            return response()->json(['token' => $token, 'is_phone_verified' => auth()->user()->is_phone_verified, 'user' => $user], 200);
        } else {
            $errors = [];
            array_push($errors, ['code' => 'auth-001', 'message' => translate('messages.Unauthorized')]);
            return response()->json([
                'errors' => $errors
            ], 401);
        }
    }
}
