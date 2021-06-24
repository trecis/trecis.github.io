# TREC-IS Classification and Prioritization Submissions

This repo holds the official TREC-IS message classification and ranking leaderboard and describes the process for submitting runs.
All associated data for the task (corpus, training data, ontologies, etc.) are held on [this page](https://trecis.org).

This leaderboard is based on the TREC-IS `2021-A` test topics available [here](http://dcs.gla.ac.uk/~richardm/TREC_IS/2020/data.html). 
The [2021-A Submission Guidelines](http://dcs.gla.ac.uk/~richardm/TREC_IS/2021/2021A/TREC%202021-A%20Incident%20Streams%20Track.pdf) describe this task in more detail.

**NOTE** The instructions and formatting for this repository and leaderboard borrow heavily from the [MSMARCO-Document-Ranking-Submissions](https://github.com/microsoft/MSMARCO-Document-Ranking-Submissions) repository, which has an excellent set up for evaluations, "coopetition", and leaderboards for ML-based challenges.

## Submission Instructions

To make a submission, please follow these instructions:

1. Download the TREC-IS [2021-A test topics](http://dcs.gla.ac.uk/~richardm/TREC_IS/2021/2021A/2021a.topics) and the associated Twitter data by following [these instructions](http://dcs.gla.ac.uk/~richardm/TREC_IS/2020/data.html). For each tweet in this dataset, provide a set of information types and a priority score, and package them according to the [2021-A Submission Guidelines](http://dcs.gla.ac.uk/~richardm/TREC_IS/2021/2021A/TREC%202021-A%20Incident%20Streams%20Track.pdf).

2. Decide on a submission id, which will be a permanent (public) unique key. The submission id should be of the form `yyyymmdd-foo`, where `foo` can be a suffix of your choice, e.g., your organization/group name.
Please keep the length reasonable.
See [here](https://github.com/infeco/trecis.boards/tree/main/submissions) for examples.
`yyyymmdd` should correspond to the submission date of your run.

3. In the directory `submissions/`, create the following files:
   1. `submissions/yyyymmdd-foo/run.json.gz` - run file on the evaluation tweets (info-type labels and priority scores for tweets in `TRECIS-CTIT-H-*.json.gz`), gz-compressed.
   2. `submissions/yyyymmdd-foo/metadata.json`, in the following format:

       ```
        {
          "organization": "org name",
          "model_description": "model description",
          "uses_users": 1,          // Does this run make use of user profiles? 1 if yes, 0 if no
          "uses_neural": 1,         // Does this run use neural language models? 1 if yes, 0 if no
          "uses_external": 1,       // Does this run use external resources? 1 if yes, 0 if no. If yes, please describe in `model_description`
          "type": "automatic",      // either 'automatic' or 'manual'
          "paper": "url",           // URL to paper
          "code": "url"             // URL to code or github repo
        }
       ```
       Leave the value of `paper` and `code` empty (i.e., the empty string) if not available.
       These fields correspond to what is shown on the leaderboard.

4. Run our check script to make sure everything is in order (and fix any errors). This script will produce an `*.errorlog` file that describes errors found in the file:
   ```bash
   $ perl eval/check_incident.pl submissions/yyyymmdd-foo/run.json.gz
   ```

5. After correcting any errors the check script reveals, add the `*.errlog` file to your repository in your `submissions/yyyymmdd-foo` directory.

6. Open a pull request against this repository.
The subject (title) of the pull request should be "Submission yyyymmdd-foo", where `yyyymmdd-foo` is the submission id you decided on.
This pull request should contain exactly three files:
   1. `submissions/yyyymmdd-foo/run.json.gz` - the compressed run file
   2. `submissions/yyyymmdd-foo/run.json.gz.errlog` - the errlog file from the check script
   3. `submissions/yyyymmdd-foo/metadata.json` - the metadata file



## Additional Submission Guidelines

The goal of the TREC-IS leaderboard is to encourage [coopetition](https://en.wikipedia.org/wiki/Coopetition) (cooperation + competition) among  groups working on crisis informatics and making social media and microblog data more informative and useful for disaster management personnel.
So, while we encourage friendly competition between different participating groups for top positions on the leaderboard, our core motivation is to ensure that over time the leaderboard provides meaningful scientific insights about how different methods compare to each other and answer questions like whether we are making real progress as a research community.
All participants are requested to abide by this spirit of coopetition and strictly observe good scientific principles when participating.
We will follow an honor system and expect participants to ensure that they are acting in compliance with both the policies and the spirit of this leaderboard.
We will also periodically audit all submissions ourselves and may flag issues as appropriate. 

### Frequency of Submission

We discourage modeling decisions based eval numbers to avoid overfitting to the set.
To ensure this, we request participants to submit:

1. No more than 2 runs in any given period of 7 days.
2. No more than 1 run with very small changes, such as different random seeds or different hyper-parameters (e.g., small changes in number of layers or number of training epochs).

Participants who may want to run ablation studies on their models are encouraged to do so using prior TREC-IS edition data but not on the eval set.

### Metadata Updates

The metadata you provide during run submission is meant to be permanent.
However, we do allow "reasonable" updates to the metadata as long as it abides by the spirit of the leaderboard (see above).
These reasons might include adding links to a paper or a code repository, fixing typos, clarifying the description of a run, etc.
However, we reserve the right to reject any changes.

It is generally expected that the team description in the metadata file will include the name of the organization (e.g., university or company).
In many cases, submissions explicitly list the contributors of the run.
It is _not_ permissible to submit a run under an alias (or a generic, nondescript team) to first determine "how you did", and then ask for a metadata change only after you've been shown to "do well".
We will reject metadata change requests in these circumstances.
Thus, you're advised to make the team description as specific as possible, so that you can claim "credit" for doing well.

Once you've created a new metadata JSON file (i.e., `submissions/yyyymmdd-foo/metadata.json`), send us a pull request with it.
Please make the subject of the pull request something obvious like "Metadata change for yyyymmdd-foo".
Also, please make it clear to us that _you_ have "permission" to change the metadata, e.g., the person making the change request is the same person who performed the original submission. 

### Anonymous Submissions

We _do_ allow anonymous submissions.
Note that the purpose of an anonymous submission is to support blind reviewing for corresponding publications, not as a probing mechanism to see how well you do, and then only make your identity known if you do well.

Anonymous submissions should still contain accurate team and model information in the metadata JSON file, but on the leaderboard we will anonymize your entry.
By default, we allow an embargo period of anonymous submissions for up to nine months.
That is, after nine months, your identity will be revealed and the leaderboard will be updated accordingly.
Additional extensions to the embargo period based on exceptional circumstances can be discussed on a case-by-case basis; please get in touch with the organizers.

For an anonymous submission, the metadata JSON file should have an additional field:

```
"embargo_until": "yyyy/mm/dd"
```

Where the date in `yyyy/mm/dd` format cannot be more than nine months past the submission date.
For example, if the submission date is 2021/06/01, the longest possible embargo period is 2022/03/01.
Of course, you are free to specify a shorter embargo period if you wish.

Note that even with an anonymous submission, the submission id is publicly known, as well as the person performing the submission.
You might consider using a random string as the submission id, and you might consider creating a separate GitHub account for the sole purpose of submitting an anonymous run.
Neither is necessary; we only provide this information for your reference.


## Legal Notices

The documentation and other content in this repository is released under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](LICENSE) file.
It grants you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.


