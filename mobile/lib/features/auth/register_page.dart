import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState()=>_RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final name=TextEditingController(), username=TextEditingController(), email=TextEditingController(), password=TextEditingController();
  bool loading=false; String? error;
  Future<void> submit() async {
    setState(()=>{loading=true,error=null});
    try { final r=await ApiClient.instance.dio.post('/auth/register',data:{'displayName':name.text.trim(),'username':username.text.trim(),'email':email.text.trim(),'password':password.text});
      await ApiClient.instance.saveToken(r.data['accessToken']); if(mounted)context.go('/home');
    } catch(e){if(mounted)setState(()=>error='Não foi possível criar a conta. Verifique os dados.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Criar conta')),body:ListView(padding:const EdgeInsets.all(24),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'Nome de exibição')),const SizedBox(height:12),
    TextField(controller:username,decoration:const InputDecoration(labelText:'Usuário (ex: emanuel)')),const SizedBox(height:12),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail')),const SizedBox(height:12),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Senha (mín. 6 caracteres)')),
    if(error!=null)...[const SizedBox(height:12),Text(error!,style:const TextStyle(color:Colors.redAccent))],const SizedBox(height:20),
    SizedBox(height:54,child:FilledButton(onPressed:loading?null:submit,child:Text(loading?'Criando...':'Criar conta'))),
  ]));
}
