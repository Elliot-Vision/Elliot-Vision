import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/security.dart';
import '../models/wave_analysis.dart';
import '../services/app_store.dart';
import '../services/market_data_service.dart';
import '../widgets/price_chart.dart';

class SecurityDetailScreen extends StatefulWidget {
  const SecurityDetailScreen({super.key, required this.security, required this.store, required this.marketData});
  final Security security;
  final AppStore store;
  final MarketDataService marketData;
  @override State<SecurityDetailScreen> createState()=>_SecurityDetailScreenState();
}

class _SecurityDetailScreenState extends State<SecurityDetailScreen> {
  late final Future<SecuritySnapshot> _snapshot;
  final _analyzer=const ElliottWaveAnalyzer();
  final Set<String> _visible={'primary'};
  bool _fib=true;
  @override void initState(){super.initState();_snapshot=widget.marketData.loadSnapshot(widget.security);}

  String biasText(MarketBias b)=>switch(b){MarketBias.bullish=>'Bullisch',MarketBias.neutral=>'Neutral',MarketBias.bearish=>'Bärisch'};
  Color biasColor(MarketBias b)=>switch(b){MarketBias.bullish=>const Color(0xFF14804A),MarketBias.neutral=>const Color(0xFF9A6B00),MarketBias.bearish=>const Color(0xFFB3261E)};

  @override Widget build(BuildContext context){
    final euro=NumberFormat.currency(locale:'de_DE',symbol:'€');
    return Scaffold(
      appBar:AppBar(title:Text(widget.security.symbol),actions:[AnimatedBuilder(animation:widget.store,builder:(_,__)=>IconButton(onPressed:()=>widget.store.toggleFavorite(widget.security),icon:Icon(widget.store.isFavorite(widget.security.isin)?Icons.star:Icons.star_border)))]),
      body:FutureBuilder<SecuritySnapshot>(future:_snapshot,builder:(context,s){
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        final data=s.data!;final a=_analyzer.analyze(data);final status=biasColor(a.bias);
        return ListView(padding:const EdgeInsets.fromLTRB(20,8,20,60),children:[
          Text(data.security.name,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700)),
          const SizedBox(height:4),Text('${data.security.isin} · ${data.security.currency}',style:const TextStyle(color:Colors.black54)),
          const SizedBox(height:18),Text(euro.format(data.currentPriceEur),style:Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight:FontWeight.w700)),
          const SizedBox(height:16),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
            Row(children:[Container(width:10,height:10,decoration:BoxDecoration(color:status,shape:BoxShape.circle)),const SizedBox(width:8),Text(biasText(a.bias),style:TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:status)),const Spacer(),Text('${a.score}/100',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700))]),
            const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(99),child:LinearProgressIndicator(value:a.score/100,minHeight:8,backgroundColor:const Color(0xFFE9E9E5),color:status)),
            const SizedBox(height:8),const Align(alignment:Alignment.centerLeft,child:Text('Analyse-Score: Klarheit der aktuellen Wellenzählung',style:TextStyle(fontSize:12,color:Colors.black54))),
          ])),
          const SizedBox(height:14),
          Card(child:Padding(padding:const EdgeInsets.fromLTRB(10,16,10,10),child:PriceChart(snapshot:data,analysis:a,visibleCountIds:_visible,showFibonacci:_fib))),
          const SizedBox(height:12),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Chart-Ebenen',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:8),
            ...a.counts.map((count)=>SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text(count.name),subtitle:Text('${biasText(count.bias)} · ${count.probability} %'),value:_visible.contains(count.id),onChanged:(v)=>setState(()=>v?_visible.add(count.id):_visible.remove(count.id)))),
            SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:const Text('Fibonacci-Level'),value:_fib,onChanged:(v)=>setState(()=>_fib=v)),
          ]))),
          const SizedBox(height:14),
          _section(context,'Kernwerte',[
            _row('Allzeithoch',euro.format(data.allTimeHighEur)),_row('Allzeittief',euro.format(data.allTimeLowEur)),_row('Bullisches Ziel',euro.format(a.bullishTargetEur)),_row('Basisszenario',euro.format(a.baseTargetEur)),_row('Bärisches Ziel',euro.format(a.bearishTargetEur)),
          ]),
          const SizedBox(height:14),
          _section(context,'Warum diese Einschätzung?',[Text(a.summary),const SizedBox(height:10),Text('Invalidierung unten: ${euro.format(a.invalidBelowEur)}'),Text('Invalidierung oben: ${euro.format(a.invalidAboveEur)}')]),
          const SizedBox(height:14),
          _section(context,'Analysehistorie',[
            _history('Heute',biasText(a.bias),a.score,'Aktuelle Hauptzählung'),
            _history('Vor 7 Tagen','Neutral',64,'Alternative A war Hauptszenario'),
            _history('Vor 21 Tagen','Bärisch',78,'ABC-Korrektur erkannt'),
          ]),
          const SizedBox(height:14),const Text('Hinweis: Diese Version verwendet Demo-Kurse und eine vereinfachte Analyseheuristik. Keine Anlageberatung.',style:TextStyle(fontSize:12,color:Colors.black54)),
        ]);
      }),
    );
  }

  Widget _section(BuildContext context,String title,List<Widget> children)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:12),...children])));
  Widget _row(String l,String v)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(l,style:const TextStyle(color:Colors.black54))),Text(v,style:const TextStyle(fontWeight:FontWeight.w600))]));
  Widget _history(String date,String state,int score,String note)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:8,height:8,margin:const EdgeInsets.only(top:6),decoration:const BoxDecoration(color:Colors.black,shape:BoxShape.circle)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$date · $state · $score/100',style:const TextStyle(fontWeight:FontWeight.w600)),Text(note,style:const TextStyle(color:Colors.black54))]))]));
}
