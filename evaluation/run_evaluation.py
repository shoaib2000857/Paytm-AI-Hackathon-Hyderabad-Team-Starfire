import sys, time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parents[1]/"backend"))
from main import parse_demo, rank_merchants

CASES=[]
for text in [
 "1 kg eggless chocolate cake under ₹800 tomorrow before 7 PM",
 "Kal eggless chocolate cake 800 rupaye ke andar chahiye",
 "Need one kilo chocolate eggless cake below Rs 800 tomorrow",
 "Repu evening eggless chocolate cake kavali budget 800",
 "Chocolate cake without egg, 1 kilo, tomorrow, ₹800 max",
 "Custom eggless chocolate cake kal 7 baje tak under 800",
 "Cake chahiye chocolate eggless one kg budget ₹800",
 "Tomorrow birthday cake chocolate eggless within 800",
 "Nearby bakery for 1kg eggless chocolate cake under 800",
 "Need eggless chocolate custom cake ₹800 tomorrow",
]: CASES.append((text,"bakery",800,"M001"))
for text in [
 "iPhone 15 screen aaj replace karwana hai, 4k ke andar",
 "Need iPhone 15 display replacement today under ₹4000",
 "iPhone 15 ka screen same day change, budget Rs 4000",
 "Phone repair iPhone 15 screen under 4k today",
 "Aaj iPhone 15 screen replacement chahiye ₹4000 max",
 "Replace my iPhone 15 display today within 4000",
 "iPhone screen toot gaya, model 15, aaj, budget 4k",
 "Same-day premium iPhone 15 screen replacement under ₹4000",
 "Mobile repair for iPhone 15 display today 4000 max",
 "Genuine ya premium iPhone 15 screen aaj 4k ke andar",
]: CASES.append((text,"phone_repair",4000,"M006"))
for text in [
 "Blouse Saturday tak stitch chahiye, budget ₹900, alteration included",
 "Need blouse stitching with one alteration under Rs 900",
 "Blouse stitch karna hai ₹900 budget alteration bhi",
 "Tailor for blouse and alteration within 900",
 "Saturday blouse ready chahiye, alteration, ₹900 max",
 "Stitch a blouse under 900 with alteration included",
 "Blouse stitching nearby budget Rs 900 plus alteration",
 "900 ke andar blouse silwana hai alteration ke saath",
 "Need tailor blouse service and alteration ₹900",
 "Blouse custom stitching with one alteration, max 900",
]: CASES.append((text,"tailor",900,"M009"))

correct_category=correct_budget=top3=0; latencies=[]
for text,category,budget,expected in CASES:
    start=time.perf_counter(); parsed=parse_demo(text); ranked=rank_merchants(parsed); latencies.append((time.perf_counter()-start)*1000)
    correct_category += parsed["category"]==category
    correct_budget += parsed["budget_max"]==budget
    top3 += expected in [m["id"] for m in ranked[:3]]
print(f"cases={len(CASES)}")
print(f"category_accuracy={correct_category/len(CASES):.1%}")
print(f"budget_accuracy={correct_budget/len(CASES):.1%}")
print(f"top3_recall={top3/len(CASES):.1%}")
print(f"median_parse_and_match_ms={sorted(latencies)[len(latencies)//2]:.3f}")
