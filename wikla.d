module WiklaModule;
import std.random;

class WiklaQuoter
{
	static string[] wikla_quotes=["Pääohjelman pahantahtoinen algoritmi.", "...tai kutsua metodia joka käynnistää kolmannen maailmansodan.", "Koululaiskuri tarvitsee koululaiskuria.", "Otus ilostui myöskin pääohjelmasta katsottuna.", "...viime kerralla otettiin olutta.", "Kymmenen vuotta rakennettu raketti tuhoutui nousun yhteydessä ja syynä oli C-ohjelma.", "Teemmepä mitä tahansa, ohjelma tulostaa töttöröö.", "Olious ei ole mitään sen syvällisempää, kuin että roikutaan langan päässä.", "Olen tässä itseni kanssa harrastanut mielihyvän hankintaa leikkaamalla ja liimaamalla.", "Merkittävä vähemmistö, mutta ei lähellekään enemmistö.", "...siitä riippuen päivitän nenän jommalle kummalle puolelle. Älkää yrittäkö pelkällä nenällä laskea sitä, vaikka sen voisi laskea pelkällä nenälläkin.", "Tätä en haluaisi ohjelmoida autiosaaren rannalla krapulassa.", "Jos te kirjotatte whilen tilalle esimerkiksi hilipatihippaa..."];
	static ref string quote()
	{
		return wikla_quotes[uniform(0,wikla_quotes.length)];
	}
}
