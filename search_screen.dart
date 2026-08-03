import 'package:flutter/material.dart';
import '../models/security.dart';
import '../services/app_store.dart';
import '../services/market_data_service.dart';
import 'security_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key,required this.store,required this.marketData});final AppStore store;final MarketDataService marketData;
  @override State<SearchScreen> createState()=>_SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen>{
  final _controller=TextEditingController();List<Security> _results=[];bool _loading=false;
  @override void initState(){super.initState();_search('');}
  Future<void> _search(String q)async{setState(()=>_loading=true);final r=await widget.marketData.searchByIsin(q);if(!mounted)return;setState((){_results=r;_loading=false;});}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(20,24,20,120),children:[
    Text('Elliott Vision',style:Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:5),const Text('Aktien analysieren. Wellen verstehen.'),const SizedBox(height:24),
    TextField(controller:_controller,onChanged:_search,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ISIN, Name oder Ticker')),
    const SizedBox(height:22),const Text('Wertpapiere',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:10),
    if(_loading)const Center(child:CircularProgressIndicator()) else ..._results.map((x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:8),title:Text(x.name,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text('${x.symbol} · ${x.isin}'),trailing:const Icon(Icons.arrow_forward_ios,size:16),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SecurityDetailScreen(security:x,store:widget.store,marketData:widget.marketData))))))
  ]);
}
