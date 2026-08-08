from kittens.tui.handler import result_handler
from kitty.boss import Boss


# in main, STDIN is for the kitten process and will contain
# the contents of the screen
def main(args: list[str]) -> str:
    return input("input: ")


# @result_handler(no_ui=True)
def handle_result(
    args: list[str],
    kitten_result: str,
    target_window_id: int,
    boss: Boss,
) -> None:

    w = boss.window_id_map.get(target_window_id)
    if w:
        w.paste_text("no data")

    outfile = "/home/stan/prj/dotfiles/kitty/outlog"
    with open(outfile, "w") as f:
        f.write(f"{kitten_result = }\n")
        f.write(f"{target_window_id =}\n")
        try:
            for k, v in boss.window_id_map.items():
                f.write(f"window_id: {k}\n")
                # f.write(k)
        except:
            f.write("error")
            # f.write(boss.window_id_map.get(k))

    # if w:
    #     w.paste_text(stdin_data)
    # else:
    #     w.paste_text("no data")
