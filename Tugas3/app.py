from flask import Flask, render_template
import pandas as pd

app = Flask(__name__)

@app.route("/")
def index():

    df = pd.read_csv("data/mobile_legends.csv")

    hero_terfavorit = df.loc[df["Match"].idxmax(),"Hero"]
    match_terbanyak = df["Match"].max()

    hero_winrate = df.loc[df["Winrate"].idxmax(),"Hero"]
    winrate = df["Winrate"].max()

    rata_winrate = round(df["Winrate"].mean(),2)

    return render_template(
        "index.html",
        tables=df.to_html(index=False),
        hero_terfavorit=hero_terfavorit,
        match_terbanyak=match_terbanyak,
        hero_winrate=hero_winrate,
        winrate=winrate,
        rata_winrate=rata_winrate
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
