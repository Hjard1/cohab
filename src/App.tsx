function App() {
  return (
    <main className="min-h-screen bg-neutral-950 text-neutral-100 antialiased">
      <div className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center px-6 py-20">
        <span className="text-sm font-medium uppercase tracking-[0.2em] text-emerald-400">
          cohab
        </span>

        <h1 className="mt-6 text-4xl font-semibold leading-tight tracking-tight sm:text-6xl">
          What you own,
          <br />
          together.
        </h1>

        <p className="mt-6 max-w-xl text-lg text-neutral-400">
          Track who owns what, who contributed what, and what's fair if you split
          or change your ownership share. Couple equity, done right.
        </p>

        <p className="mt-10 max-w-xl border-l-2 border-emerald-500/60 pl-4 text-base text-neutral-300">
          <span className="text-neutral-500">Splitwise tracks what you spent. </span>
          cohab tracks what you own.
        </p>

        <div className="mt-12 text-sm text-neutral-600">
          Scaffold ready · see{" "}
          <code className="rounded bg-neutral-800 px-1.5 py-0.5 text-neutral-300">
            docs/PRODUCT-SPEC.md
          </code>
        </div>
      </div>
    </main>
  );
}

export default App;
